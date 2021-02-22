#!/bin/bash

#args: full command line to benchmark, preceded by the amount of memory to flush before running it, in bytes
#a *.benchmark file will be created with the results (see below)
#another file, containing computing stats, will be created ($fileout.stats) during the run, and removed at the end of it, after its content has been appended to the .benchmark file

toflush=$1;
shift 1;
echo "Flushing memory..." 1>&2
flush_mem_cache $toflush
echo "Flushed $toflush bytes of memory." 1>&2


array=$@
#$fileout is the complete command line without shitty characters
#all stats will be output to $fileout.benchmark
fileout=`printf "%s" "${array[@]}"|sed 's/ //g'|sed 's/\//_/g'|sed 's/\.//g'`
echo "#### Memory status when starting job ####">$fileout.benchmark
echo "Just flushed $toflush bytes of memory. Dump of /proc/meminfo follows." >>$fileout.benchmark
cat /proc/meminfo >>$fileout.benchmark
echo >>$fileout.benchmark
echo "#### output of \time -v ####" >>$fileout.benchmark
echo "#### WARNING: memory and exit status stats reported by time are unreliable most of the time  ####" >>$fileout.benchmark

 #run time command
 (\time -v -- $@) 2>> $fileout.benchmark &
 # $! is the pid of 'time', not the one of the job we're timing
 ppid=$!
 sleep 0.5;

 #get pid of the job we're timing, which is the only (we assume) child process of 'time'
#echo "ps --ppid $ppid -o pid"
#ps --ppid $ppid -o pid
 pid=`ps --no-headers --ppid $ppid -o pid|sed 's/\s//g'`;
 cmd=`ps --no-headers --pid $pid -o cmd |sed 's/\s//g'`;
echo "PID monitored is - $pid - PPID is - $ppid --" 1>&2
echo "Command benchmarked is $@" 1>&2
#cat /proc/$pid/status 1>&2
# dump /proc/$pid/status every 5 seconds
 while [ -a /proc/$pid/status ]; do 
	echo >$fileout.stats
	echo "############################## COMPUTING STATS ################################">>$fileout.stats; 
	date>>$fileout.stats ;
	echo >>$fileout.stats
	echo "#### Monitored PID $pid (COMMAND: $cmd). ####" >>$fileout.stats; 	echo >>$fileout.stats; cat /proc/$pid/status>>$fileout.stats ; sleep 5; 
 done; 
 
cat $fileout.stats>>$fileout.benchmark; 
rm $fileout.stats
	echo >>$fileout.benchmark
echo "#### Memory info at end of job (dump of /proc/meminfo) ####">>$fileout.benchmark
	echo >>$fileout.benchmark


 cat /proc/meminfo>>$fileout.benchmark
	echo >>$fileout.benchmark

echo "############################## HARDWARE INFO ################################">>$fileout.benchmark
	echo >>$fileout.benchmark

echo "#### MACHINE NAME AND OS (output of 'uname -a') ####">>$fileout.benchmark
	echo >>$fileout.benchmark

uname -a >>$fileout.benchmark
	echo >>$fileout.benchmark


echo "#### CPU INFO (dump of /proc/cpuinfo) ####">>$fileout.benchmark
	echo >>$fileout.benchmark

 cat /proc/cpuinfo>>$fileout.benchmark

