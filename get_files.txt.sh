#!/bin/bash


URLprefix=$1
cutdirs=`echo $URLprefix |perl -ne '$_=~/\S+:\/\/(\S+)/; @url=split("/",$1); print $#url'`

for dir in `cat DCC_dirs.list|grep -vP "^#"`;
do
printf "$PWD/$dir/files.txt\t$URLprefix/$dir\n"
wget_mirror.sh $PWD $URLprefix/$dir/files.txt $dir ~/email_recipients.txt $cutdirs&
done

