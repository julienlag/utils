#!/bin/bash
source ~/.bashrc
targetDir=~/READMEs/seldomUsed/

for file in `cat readmes.list `; do
target=$(fullpath $file)
\mv -f $file $file.bkp
uuid=`uuidgen`
\mv -f $target $(dirname $target)/README_$uuid.sh
echo "mv $target $(dirname $target)/README_$uuid.sh"
\ln -f -s $(dirname $target)/README_$uuid.sh $file
done &> readmes.cleanup.txt

