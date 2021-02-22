#!/bin/bash

# DON'T CALL SHELL VARIABLES IN THE SCRIPTS SENT TO 'MAKE', IT WILL INTERFERE WITH MAKE VARIABLES!!!

# usage example: 
#                     make_parallel /users/rg/projects/encode/scaling_up/whole_genome/encode_DCC_mirror/joblist.txt 10

#                                  1st arg is list of shell jobs to run (one job per line, with no variables)
#                                  2nd arg is number of jobs (commands) to run simultaneously (sent to "-j" option of 'make')

joblist=$1;
parjobs=$2;
rand=$RANDOM
makefile="/tmp/par.$rand.makefile"
echo "makefile is $makefile">&2
printf "all: " > $makefile
cat $1| while read job; do chmod a+x $job; jobname=`echo $job| sed 's/[^A-Za-z0-9]//g'`; printf "$jobname " >>$makefile; done
echo "" >>$makefile
cat $1| while read job; do jobname=`echo $job| sed 's/[^A-Za-z0-9]//g'`; echo "$jobname: " >>$makefile; printf "\t">> $makefile; echo $job >> $makefile; done

make --quiet -j $parjobs all -f $makefile 
