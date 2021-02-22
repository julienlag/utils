#!/bin/bash

#first arg is PSL file
#maps splice sites on a genome-mapped RNA sequence based on a PSL file (BLAT output file)  


printf "#seqId\tseqSize\tIntronPosition\tIntronSizeOnGenome\n"; 
perl -ne 'chomp; @line=split "\t"; @blockSizes=split(",", $line[18]) ; @QblockStarts=split(",", $line[19]); @SblockStarts=split(",", $line[20]); for($i=1;$i<=$#SblockStarts;$i++){ if($line[8] eq "+") {$intronSize= $SblockStarts[$i] - ($SblockStarts[$i-1] + $blockSizes[$i-1]); print "$line[9]\t$line[10]\t$QblockStarts[$i]\t$intronSize\n"} else { $intronSize = $SblockStarts[$i] - ($SblockStarts[$i-1] + $blockSizes[$i-1]); $splicesite=$line[10]-$QblockStarts[$i]; print "$line[9]\t$line[10]\t$splicesite\t$intronSize\n"} }' $1
