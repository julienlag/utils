#!/bin/bash
#set -e
source ~/.bashrc
targetDir=~/READMEs/seldomUsed/
date >&2
echo "Searching READMEs in $HOME...">&2
find -L ~ -xtype f -name "README*.sh" | grep -v -f ~/READMEs_excludeList.txt> ~/READMEs/READMEs.toSoftLink.list
echo "Done searching READMEs in $HOME.">&2

date >&2
cd $targetDir
for file in `cat ~/READMEs/READMEs.toSoftLink.list`; do
dirname=`dirname $file`
#fileName="README_"`echo $file | sed 's?^/??'| sed 's?/?_?g' | sed 's/users_rg_jlagarde_//g'`
fileName="README_"`uuidgen`".sh"
echo $file >&2
if [ ! -e $fileName ]
then
# ln -s $file $fileName
mv $file $targetDir/$fileName
fp=`fullpath $fileName`
cd $dirname 
ln -s $fp $file
cd $targetDir
echo -e "\n\tCreated $fileName !!!\n" >&2
else
echo -e "$fileName already exists" >&2
fi
done
