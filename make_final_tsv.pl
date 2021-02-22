#!/usr/local/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
use diagnostics;

open F, "grep -v -P \"^#\" $ARGV[0]|" or die $!;

print STDOUT "#Primer id
#Tissue(s)
#Distance Primer start / RF start
#RF/locus pair id
#Total number of occurrences of RF
#Total number of occurrences of pair (i.e. how many times RF is assigned to locus)
#Number of tissues in which the pair is observed
#Number of different primers from locus l to which RF is assigned
#Assignment Confidence Score
#Internal RF (bool)
#Exonic RF (bool)
#Genic RF (bool)
#Best splice site geneid score
#Best splice site coord
#Seq on 5' side of (RF, SP) pair
#Seq on 3' side of (RF, SP) pair
#Primer seq, 5', external
#Primer seq, 5', internal
#Primer seq, 3', external
#Primer seq, 3', internal
";
while (<F>){
	my @line=split "\t";
	my $line=$_;
	chomp $line;
	my $pair=$line[3];
	my $fiveint;
	my $threeint;
	my $fiveext;
	my $threeext;
	open F2, "$ARGV[1]" or die $!;
	my $extprimersfound=0;
	my $intprimersfound=0;
	while(<F2>){
		if($_=~/^($pair)\t(\S+)\t(\S+)\t\S+\n/){
			$fiveext=$2;
			$threeext=$3;
			$extprimersfound=1;
		}
		elsif($_=~/^($pair)_internal\t(\S+)\t(\S+)\t\S+\n/){
			$fiveint=$2;
			$threeint=$3;
			$intprimersfound=1;
		}
		if($extprimersfound==1 && $intprimersfound==1){
			last;
		}
	}
	close F2;
	if($extprimersfound==0 || $intprimersfound==0){
		warn "$pair: primer not found in $ARGV[1]\n";
	}
	else{
		print STDOUT "$line\t$fiveext\t$fiveint\t$threeext\t$threeint\n";
	}
}
