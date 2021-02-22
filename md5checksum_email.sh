#!/bin/bash
#need to be launched from dir where the md5 file is
md5sum -c $1 > $1.log
err=$?
recipients=`head -n1 $2`
subject=`echo $PWD| sed 's/.*\/encode_DCC_mirror\///g'`
#err=`grep ": FAILED " $1.log|wc -l`
#errString=`grep ": FAILED " $1.log|grep -v ".bai:"`
if [ "$err" -ne 0 ]
then
subject2='ERRORS=1'
else
subject2='ERRORS=0'
fi
job=`md5sum $1| awk '{print $1}'`
printf "subject\tmd5checksum $subject $subject2
recipient\t$recipients
fileattach\t$1.log
body\tmd5checksum -c $PWD/$1:
" > /tmp/$job.mail.txt
mailer.pl <  /tmp/$job.mail.txt &> $job.mail.log

#rm -f /tmp/$job.mail.txt /tmp/$job.log.txt 

