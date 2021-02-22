#!/bin/bash

# summarizes job exit status for a given batch of queued jobs ran with "queue_anything.sh"

# INPUT:
# input ($1) should be space-separated:
#   col 1: sh file path (i.e. the script that was queued)
#   col 2: path to associated stdout file (#$ -o) (ignored)
#   col 3: path to associated stderr file (#$ -e)

# OUTPUT
# output is col1-2-3 of input, plus columns 4-5:
#   col 4: boolean for "Job has finished correctly" (looks for "XXdoneXX" string in the last 3 lines of the job's err file)
#   col 5: boolean for "Job has errors" (looks for "XXerrorXX" string in the the job's err file)
# col4 and col5 should never contain the same value.
 

# EXAMPLES:

## basic usage: 
# cat *.jobShOutErr.tsv |jobs_exit.sh -

## get list of failed jobs:
# cat *.jobShOutErr.tsv |jobs_exit.sh - | awk '$4==0 && $5==1'

## get list of successfully finished jobs:
# cat *.jobShOutErr.tsv |jobs_exit.sh - | awk '$4==1'

## get list of jobs UNFINISHED (i.e. still running, killed or hung):
# cat *.jobShOutErr.tsv |jobs_exit.sh - | awk '$4==0 && $5==0'

echo -e "#script\tStdOutFile\tStdErrFile\tXXdoneXX\tXXerrorXX"
cat $1 | while read script out err; do
finished=`tail -n3 $err | grep -m1 -c XXdoneXX`
error=`cat $err | grep -m1 -c XXerrorXX`
if [ "$error" == 1 ] && [ "$finished" == 1 ]; then
echo "died! your file ($err) contains both the 'XXerrorXX' and 'XXdoneXX' strings. THis should never happen." >&2
exit 1;
fi
echo -e "$script\t$out\t$err\t$finished\t$error"
done
