#!/usr/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
use diagnostics;

open F, "$ARGV[0]" or die $!;

#$/=">";

my $seqid='';
while(<F>){
	chomp;
	if($_=~/^>(\S+) (\d+) (\d+)$/){
		$seqid=$1;
		#print "$seqid\n";
	}
	else{
		my @line=split "\t";
		$line[1]=~/(\D+)(\d+)/;
		print "$seqid\t$1\t$line[0]\t$2\tXX\tXX\t0\t$line[2]\n";
	}

}

#chr1_110237359_110237841_2:0:0_2:0:0_c/1        +       chr1    110237358       AAACGGGGATGCCCCTTTGCAAAGCTGTTGTGCTGAGCCATTGCATGTCAGACTCCTTGCGAATTCGCTTTAGAGATTGTTGTTCATTAGTCGAACATCCATTCAGCACATTTATTGTGTTCTCAGTGTGTGCTATGTGCTGTTCTGTGG  IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII  0       3:T>C,120:G>T
