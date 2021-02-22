#!/bin/bash

currdir=$1
url=$2
job=$3 #no final "slash"!
cutdirs=$5
user=$6
password=$7
job=`echo $job|sed 's/\//_/g'`
jobstr=`echo $job | perl -ne 'if(length($_)>20){$str=substr($_, 0, 20); print "$str..."} else{print}'` #shorten job name to put in subject line
cd $currdir
recipients=`head -n1 $4`
#wget --continue --mirror --verbose --reject "*.htm*" --no-check-certificate --tries=20 --no-parent -nH --user=$user --password=$password --cut-dirs=3 -o $job.log  $url; 
wget -N --mirror --verbose --reject "*.htm*,.listing" --no-check-certificate --tries=0 --no-parent -nH --user=$user --password=$password --cut-dirs=$cutdirs -o $job.log  $url; 

head $job.log > /tmp/$job.log.txt; 
printf "\n\n\n[ ........... ]\n\n\n">> /tmp/$job.log.txt 
tail -n20 $job.log >> /tmp/$job.log.txt 
nberrors=`grep "ERROR\|Giving up\|Name or service not known" $job.log|wc -l`
errorsdetected=''
if [ $nberrors -gt 0 ]
then
errorsdetected=1
else
errorsdetected=0
fi
finished=`tail $job.log|grep FINISHED`
finishedbool=`tail $job.log|grep FINISHED|wc -l`
if [ $finishedbool == 0 ]
then
finishedbool=`tail -n2 $job.log|grep "Server file no newer than local file"|wc -l`
fi
downloaded=`tail $job.log|grep Downloaded| sed 's/Downloaded: //g'`
printf "subject\twget $jobstr: FINISHED=$finishedbool, ERRORS=$errorsdetected (number: $nberrors), $downloaded 
recipient\t$recipients
fileattach\t/tmp/$job.log.txt
body\tFind attached bits of the wget log file. Original directory is $currdir . $finished\n" > /tmp/$job.mail.txt
sleep 2
mailer.pl <  /tmp/$job.mail.txt &> $job.mail.log

rm -f /tmp/$job.mail.txt /tmp/$job.log.txt 
