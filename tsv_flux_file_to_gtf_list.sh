#!/bin/bash
#lab=cshl
#basedir=/users/rg/jlagarde/projects/encode/scaling/whole_genome/analysis/flux_capacitor/$lab
tsvFile=$1
basedir=`dirname $tsvFile`
cat $tsvFile | while read bedfile annot
do
basebedtmp=`basename $bedfile`
basebed=${basebedtmp%.bed.gz}
baseannot=`basename $annot`
jobid=$basebed.$baseannot
ls $basedir/flux_out/$jobid.gtf >&2
printf "$bedfile\t$annot\t$basedir/flux_out/$jobid.gtf\n"
done
