#!/bin/bash

# usage example: 
# bash mirror_loop.sh hg19

URLprefix=$1
for dir in `cat DCC_dirs.list|grep -vP "^#"`;
do
printf "$PWD/$dir/files.txt\t$URLprefix/$dir\n"
wget_mirror.sh $PWD $URLprefix/$dir/files.txt $dir email_recipients.txt&
done

