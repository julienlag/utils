#!/bin/bash
set -e
file=$1
genomeFai=$2
bn=`basename $file .bam`

for strand in `echo "+ -"`;
do
echo "making bedGraph $strand strand" >&2
genomeCoverageBed -strand $strand -split -bg -ibam $file >  $bn\_$strand\strand.bedgraph
echo "making bigWig $strand strand" >&2
bedGraphToBigWig $bn\_$strand\strand.bedgraph $genomeFai $bn\_$strand\strand.bigwig 
done

