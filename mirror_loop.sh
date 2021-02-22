#!/bin/bash

# usage example: 
# bash mirror_loop.sh hg19

URLprefix=$1
user=$2
password=$3
#calculate number of directories to cut in wget:
cutdirs=`echo $URLprefix |perl -ne '$_=~/\S+:\/\/(\S+)/; @url=split("/",$1); print $#url'`
URLprefix=`echo $URLprefix|sed 's?/$??'`
printf "all: ">wget.makefile
for dir in `cat DCC_dirs.list|grep -vP "^#"`;
do
dir=`echo $dir|perl -ne '$_=~s/^\.(.+)/$1/g; print'`
# 's?^\.??'`

#echo $dir
for file in `cut -f1 $dir/files.txt |grep -vP "/$"`; #filter out directory entries (assumed to end with "/", otherwise wget will download everything recursively)
do
file=`echo $file|sed 's?^\./??'`
jobname=`echo $dir$file.job| sed 's/[!@#\$%^&*()]//g'`
printf "$jobname "
#printf "\t/users/rg/jlagarde/julien_utils/wget_mirror.sh $PWD http://hgdownload-test.cse.ucsc.edu/goldenPath/$assembly/encodeDCC/$dir/ $dir/$file\n"
done
done >> wget.makefile
echo "" >>wget.makefile

for dir in `cat DCC_dirs.list|grep -vP "^#"`;
do
dir=`echo $dir|perl -ne '$_=~s/^\.(.+)/$1/g; print'`
#echo $dir
for file in `cut -f1 $dir/files.txt | grep -vP "/$"`;
do
file=`echo $file|sed 's?^\./??'`
jobname=`echo $dir$file.job| sed 's/[!@#\$%^&*()]//g'`
echo "$jobname:"
printf "\t";
echo "/users/rg/jlagarde/julien_utils/wget_mirror.sh $PWD $URLprefix/$dir/$file $jobname ~/email_recipients.txt $cutdirs $user $password"
#echo "u= '$URLprefix' d='$dir' f='$file'" >&2
#echo "/users/rg/jlagarde/julien_utils/wget_mirror.sh $PWD $URLprefix/$dir/$file $jobname ~/email_recipients.txt $cutdirs $user $password"  >&2
done
done >> wget.makefile
