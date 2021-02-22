#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use Data::Dumper;


open F, "grep -v -P \"^#\" $ARGV[0]| sort -k9,9n|" or die $!;
print STDOUT "#RACE primer id
#Tissue(s) the (RF, primer) pair is seen in
#Distance RACE primer start / RF start
#RF/locus pair id ({chr}_{RF_start}_{RF_end}_{locus id})
#Total number of occurrences of RF in chr21/22 experiments
#Total number of occurrences of (RF, locus) pair (i.e. how many times RF is assigned to locus) in chr21/22 experiments
#Number of tissues in which the pair is observed
#Number of different primers from locus to which RF is assigned
#Assignment Confidence Score
#Internal RF (bool)
#Exonic RF (bool)
#Genic RF (bool)
#Best splice site geneid score for RF
#Best splice site coord for RF
#Seq on 5' side of (RF, SP) pair (either RF or SP sequence, depending on orientation of RACE)
#Seq on 3' side of (RF, SP) pair (either RF or SP sequence, depending on orientation of RACE)
#RT-PCR Primer seq, 5', external
#RT-PCR Primer seq, 5', internal
#RT-PCR Primer seq, 3', external
#RT-PCR Primer seq, 3', internal
";

my %locus_seen;

while (<F>){
	my @line= split "\t";
	my $line=$_;
	my $pair = $line[3];
	my $locus = '';
	if(	$pair=~/^\S+_\d+_\d+_(\S+)$/){
		$locus = $1;
		if(exists $locus_seen{$locus}){
			next;
		}
		else{
			$locus_seen{$locus}=1;
			print STDOUT $line;
		}
	}
	else{
		die;
	}
}
