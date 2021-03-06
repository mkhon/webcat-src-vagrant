#!/bin/sh
cd `dirname $0`
set -e

if [ ! -f /usr/bin/javac ] ; then
    # Add openjdk 8 repo
    sudo add-apt-repository ppa:openjdk-r/ppa

    # Need to update or else the installs won't work
    sudo DEBIAN_FRONTEND=noninteractive apt-get -q update

    # Some things we need to build Web-CAT.
    sudo DEBIAN_FRONTEND=noninteractive apt-get -q install -y openjdk-8-jdk ant git

    # Remove openjdk-7-jre-headless if it is installed
    sudo DEBIAN_FRONTEND=noninteractive apt-get -q remove -y openjdk-7-jre-headless
fi

fetch()
{
	url="$1"
	file="`basename $url`"

	curl -sSL "$url" -o "$file.tmp" && mv "$file.tmp" "$file"
}

# install WebObjects
[ -f WOInstaller.jar ] || fetch http://wocommunity.org/tools/WOInstaller.jar
wodir=/Library/WebObjects/Versions/WebObjects543
sudo mkdir -p $wodir
[ -d $wodir/Library/Frameworks/JavaXML.framework ] || (sudo java -jar WOInstaller.jar 5.4.3 $wodir >/dev/null || (sudo rm -rf $wodir && exit 1))

# install Wonder Frameworks
[ -f Wonder-Frameworks.tar.gz ] || fetch https://jenkins.wocommunity.org/job/Wonder7/lastSuccessfulBuild/artifact/Root/Roots/Wonder-Frameworks.tar.gz
sudo tar xfz Wonder-Frameworks.tar.gz -C $wodir/Library/Frameworks

# woproject.jar
[ -f woproject.jar ] || fetch http://www.wocommunity.org/tools/woproject.jar
mkdir -p ~/.ant/lib
cp woproject.jar ~/.ant/lib

# wobuild.properties
mkdir -p ~/Library/Frameworks
cat >~/Library/wobuild.properties << EOF
wo.wosystemroot=$wodir
wo.woroot=$wodir
wo.user.frameworks=$HOME/Library/Frameworks
wo.system.frameworks=$wodir/Library/Frameworks
wo.bootstrapjar=$wodir/Library/WebObjects/JavaApplications/wotaskd.woa/WOBootstrap.jar
wo.network.frameworks=/Network/Library/Frameworks
wo.api.root=/Library/WebObjects/ADC%20Reference%20Library/documentation/WebObjects/Reference/API
wo.network.root=/Network
wo.extensions=$wodir/Local/Library/WebObjects/Extensions
wo.user.root=$HOME
wo.local.frameworks=$wodir/Local/Library/Frameworks
wo.dir.local.library.frameworks=$wodir/Local/Library/Frameworks
wo.apps.root=$wodir/Local/Library/WebObjects/Applications
wo.wolocalroot=$wodir
wo.dir.user.home.library.frameworks=$HOME/Library/Frameworks
EOF
sudo chown -R $USER $wodir/Library/Frameworks

# If the source isn't checked out, check it out.
if [ ! -d web-cat ] ; then
    mkdir -p web-cat
    git clone -q https://github.com/mkhon/web-cat web-cat
fi

#(cd web-cat/Web-CAT && ant build.subsystems build.redistributable.war)
