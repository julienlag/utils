#!/bin/bash
#set -e
source ~jlagarde/.bashrc
targetDir=~jlagarde/ubuntuConfigBackup/

#save package list etc
 rsync -aqP --delete /etc/apt/sources.list* $targetDir/apt/
dpkg --get-selections > $targetDir/apt/packages.list
apt-key exportall > $targetDir/apt/repositories.keys 2>/dev/null

#save gnome settings
#dconf dump / > $targetDir/gnome_settings.txt

#save bash config
cp --preserve ~jlagarde/.profile $targetDir/
cp --preserve ~jlagarde/.bashrc $targetDir

#cp autofs config
rsync -aqP --delete /etc/auto* $targetDir/etc/
#cp sudoers config
rsync -aqP --delete /etc/sudoers $targetDir/etc/
#cp package manager config
cp /etc/apt/apt.conf.d/20auto-upgrades $targetDir/etc/apt/apt.conf.d/
cp /etc/apt/apt.conf.d/50unattended-upgrades $targetDir/etc/apt/apt.conf.d/

#cp /etc/aliases (to forward system emails to gmail)
cp /etc/aliases $targetDir/etc/

#copy synthing's home .stignore file, as it's not synced with remote machines
cp $HOME/.stignore $targetDir/

#save crontab
crontab -l > $targetDir/crontab.$HOSTNAME.txt

#git version

cd $targetDir
now=`now`
 for file in `find . -type f | grep -vP "~$"| grep -vP "/\.git"|grep -vP "\./sources.list.d/"`; do
 git add $file > /dev/null
# add file to depository's index
 done;
#echo "Done gitting $dir..."
git commit -m "version $now" >/dev/null
# commit current version
