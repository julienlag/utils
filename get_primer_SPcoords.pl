#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use Data::Dumper;

open GFFPRIMERS, "$ARGV[0]" or die $!;

while (<GFFPRIMERS>){
	my @line=split "\t";
	my $chr=$line[0];
	my $primerchrstart=$line[3];
	my $primerchrstop=$line[4];
	#print "$line[8]\n";
	$line[8]=~/prname: (\S+) sp_id/;
	my $primerid=$1;
	$primerid=~/(\S+)_(\d+)_(\d+)_(\S{1})_primer_(\d{1})race_\d+$/;
	my $spchr=$1;
	my $spstart=$2;
	my $spstop=$3;
	my $spstrand=$4;
	my $race=$5;
	my $primerspstart='';
	my $primerspstop='';
	if($spstrand eq 'p'){
		$primerspstart=$primerchrstart-$spstart;
		$primerspstop=$primerchrstop-$spstart;
	}
	elsif($spstrand eq 'm'){
		$primerspstart=$spstop-$primerchrstop;
		$primerspstop=$spstop-$primerchrstart;
	}
	else{
		die;
	}
	
	print STDOUT "$primerid\t$primerspstart\t$primerspstop\n";
}
