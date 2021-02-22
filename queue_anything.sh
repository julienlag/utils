#!/bin/bash

#arg1 = workDir
#arg2 = file containing commands to queue
#arg3 = jobName
set -e

workDir=$1;
commandFile=$2;    #contains the bash commands (ONE PER LINE, IN ORDER TO BE CHECKED BY check_pipe_exit.sh) to be sent to the queue.
                   # CAREFUL: this script will introduce a:
                   #     'if [ \"\$(check_exit)\" != \"0\" ]; then echo \"XXerrorXX\" >&2; exit 1; fi'
                   # statement between each line of the commandFile. If the commandFile is not "properly" formatted (e.g. if/then of the same statement not on the same line) there will be horrible syntax errors in the output!
jobName=$3;   #should be between single quotes if contains variables not to be expanded

#command=`cat $commandFile`

command=`eval "echo -e \"\`cat $commandFile\`\""`   #allows expanding variables within $commandFile. ALL VARIABLES TO BE EXPANDED IN COMMANDFILE MUST BE EXPORTED FROM THE PARENT SHELL BEFOREHAND

# echo -e "\n\tPARAM SUMMARY:">&2
 echo -e "\n\tjobName = $jobName">&2
 #echo -e "\n\tcommand = '${command[0]}'">&2
 #echo -e "\n\tworkDir = $workDir\n">&2
err=$workDir/logs/$jobName.err
out=$workDir/logs/$jobName.out
mkdir -p $workDir/logs/
rm -f $err
# print header
 echo "
#!/bin/bash
#$ -S /bin/bash
#$ -V
#$ -e $err
#$ -o $out
#$ -N $jobName
set -e

cd $workDir
date >&2
source ~jlagarde/julien_utils/check_pipe_exit.sh
echo 'Running on' \$HOSTNAME >&2
echo 'ENVIRONMENT VARIABLES BEGIN ' >&2
env >&2
echo 'ENVIRONMENT VARIABLES END ' >&2

" > $jobName.sh
# done printing header

#print commands one by one:
OLD_IFS=$IFS
IFS=$'\n'

for line in $(echo "$command"); do
echo "date >&2" >> $jobName.sh
echo "${line}" >> $jobName.sh
#echo "date >&2" >> $jobName.sh
if [[ ${line} =~ \| ]]; # if command contains a pipe
then
echo "if [ \"\$(check_exit)\" != \"0\" ]; then echo \"XXerrorXX\" >&2; exit 1; fi" >> $jobName.sh
fi
done
IFS=$OLD_IFS
#done printing commands one by one:
echo "date >&2" >> $jobName.sh
#print tail:
echo "echo \"XXdoneXX\" >&2" >> $jobName.sh
echo "exit 0" >> $jobName.sh

echo -e "$jobName.sh\t$out\t$err" > $jobName.jobShOutErr.tsv
