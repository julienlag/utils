#!/bin/bash
export run_id=$(date +%Y%m%d)
runLoops="20" #number of rsync loops to run before exiting
let runLoops=$runLoops+1
loopEvery="2h"
echo "run_id is $run_id"
echo "Hostname: $HOSTNAME"
echo "PID: $BASHPID"
echo
loop=0
while [ $loop -lt $runLoops ]
do
echo "Now is $(date)"
echo "Syncing logs ($(date))..."
rsync -aqP guigont:/var/log/MinKNOW/ /users/rg/jlagarde/projects/nanopore/sequencing_runs/MinKNOW_logs/
echo "Syncing sequencing data ($(date))..."
rsync -aqP --delete guigont:/var/lib/MinKNOW/data/reads /users/rg/jlagarde/projects/nanopore/sequencing_runs/runs/$run_id/
let loop=$loop+1
echo "Done loop $loop ($(date)). Starting again in $loopEvery..."
sleep $loopEvery
done

echo "XXdoneXX"
