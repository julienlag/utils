#!/usr/bin/perl -w

use strict;

open PSL, "$ARGV[0]" or die;

while(<PSL>){
	chomp;
	my @line=split "\t";
	unless($line[0]=~/^\d+$/){ #skips header
		next;
	}
	
	my @blockStarts=split ",", $line[20];
	my @blockStartsRel=();
	for(my $i=0;$i<=$#blockStarts; $i++){
		$blockStartsRel[$i]=$blockStarts[$i]-$line[15];
		#print STDERR "$blockStarts[$i]\t$blockStartsRel[$i]\n";
	}
	print STDOUT $line[13]."\t".$line[15]."\t".$line[16]."\t".$line[9]."\t".$line[0]."\t".$line[8]."\t".$line[15]."\t".$line[16]."\t0\t".$line[17]."\t".$line[18]."\t".join(",",@blockStartsRel)."\n";
}
