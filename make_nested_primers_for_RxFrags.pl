#!/usr/local/bin/perl -w

use warnings;
use strict;

my $firststepprimer3=$ARGV[0];
my $excludecenterfile=$ARGV[1];

open EXCLUDE, "$excludecenterfile" or die;
my %id_exclude=();
while(<EXCLUDE>){
	if($_=~/^(\S+)\t(\d+),(\d+)$/){
		push(@{$id_exclude{$1}}, $2, $3);
	}
	else {
		die "$excludecenterfile: wrong format\n";
	}
}



open BOULDER, "$firststepprimer3" or die $!;
my %primer_record=();
$/="\n=\n";
while(<BOULDER>){
	my $left_incl_region_start;
	#my $leftlength;
	my $rightstop;
	my $rightlength;
	my $firstproductsize;
	my $intprimerid;
	my $fullseqlength;
	my $extprimerid;
	#my $racetype;
	if($_=~/PRIMER_SEQUENCE_ID=(.*)\n/){
		$extprimerid=$1;
		$intprimerid=$1."_internal";
		#if($extprimerid=~/5race/){
		#	$racetype=5;
		#}
		#elsif($extprimerid=~/3race/){
		#	$racetype=3;
		#}
		#else{
		#	die "$extprimerid: Unknown racetype \n";
		#}
	}
	unless($_=~/PRIMER_\S+_SEQUENCE/){
		warn "Skipped primer $intprimerid as no external set could be designed\n";
		next;
	}
	print STDOUT "PRIMER_SEQUENCE_ID=".$intprimerid."\n";
	if($_=~/\n(SEQUENCE=(.*)\n)/){
		print STDOUT $1;
		$fullseqlength=length($2);
	}
	if($_=~/\n(PRIMER_TASK=.*\n)/){
		print STDOUT $1;
	}
	if($_=~/\n(PRIMER_OPT_SIZE=.*\n)/){
		print STDOUT $1;
	}
	if($_=~/\n(PRIMER_MIN_SIZE=.*\n)/){
		print STDOUT $1;
	}
	if($_=~/\n(PRIMER_MAX_SIZE=.*\n)/){
		print STDOUT $1;
	}
	if($_=~/\n(PRIMER_OPT_TM=.*\n)/){
		print STDOUT $1;
	}
	if($_=~/\n(PRIMER_MIN_TM=.*\n)/){
		print STDOUT $1;
	}
	if($_=~/\n(PRIMER_MAX_TM=.*\n)/){
		print STDOUT $1;
	}
	
	if($_=~/\n(PRIMER_NUM_RETURN=.*\n)/){
		print STDOUT $1;
	}
	if($_=~/\n(PRIMER_PRODUCT_SIZE_RANGE=.*\n)/){
		print STDOUT $1;
	}
	if($_=~/\n(PRIMER_MAX_GC=.*\n)/){
		print STDOUT $1;
	}
	if($_=~/\n(PRIMER_MIN_GC=.*\n)/){
		print STDOUT $1;
	}
	if($_=~/\nPRIMER_LEFT=(\d+),(\d+)\n/){
		$left_incl_region_start=$1+$2;
		#$leftlength=$2;
	}
	if($_=~/\nPRIMER_RIGHT=(\d+),(\d+)\n/){
		$rightstop=$1;
		$rightlength=$2;
	}
	if($_=~/\nPRIMER_PRODUCT_SIZE=(\d+)\n/){
		$firstproductsize=$1;
	}
	#my $leftlength=90-1;
	#my $rightlength=90-1;
	my $left_incl_region_length=$rightstop-$rightlength-$left_incl_region_start;
	#my $left_excl_region_start;
	#my $left_excl_region_length;
	#my $right_excl_region_start;
	#my $right_excl_region_length;
	my $exclude_string_left;
	my $exclude_string_right;

	if (exists $id_exclude{$extprimerid}){
		#if($racetype==5){
			my $right_excl_region_start=${$id_exclude{$extprimerid}}[0]+${$id_exclude{$extprimerid}}[1];
			my $right_excl_region_length=($left_incl_region_start+$left_incl_region_length)-40;
			#if($right_excl_region_length<=0){
			$exclude_string_right= "$right_excl_region_start,$right_excl_region_length";
			
			#}
			if($right_excl_region_length<=1 || $right_excl_region_start+$right_excl_region_length > $firstproductsize){
				$exclude_string_right='';
			}

		#}
		#else{
			my $left_excl_region_start=$left_incl_region_start+40;
			my $left_excl_region_length=${$id_exclude{$extprimerid}}[0]-$left_excl_region_start;
			$exclude_string_left="$left_excl_region_start,$left_excl_region_length";
			if ($left_excl_region_length<1 || $left_excl_region_start+ $left_excl_region_length>${$id_exclude{$extprimerid}}[0]){
				$exclude_string_left='';
			}
		#}
			
		#if($leftstart+90-1>${$id_exclude{$extprimerid}}[0]){
		#	$leftlength=${$id_exclude{$extprimerid}}[0]-$leftstart-1;
		#}
		
		#my $rightstart=$rightstop-$rightlength;
		#if($rightstart<${$id_exclude{$extprimerid}}[0]+${$id_exclude{$extprimerid}}[0]){
		#	$rightstart=${$id_exclude{$extprimerid}}[0]+${$id_exclude{$extprimerid}}[0];
		#	$rightlength=$rightstop-$rightstart;
		#}
				
		print STDOUT "INCLUDED_REGION=$left_incl_region_start,$left_incl_region_length\n";
		
		#my $excludedrightregionlength=$fullseqlength-$rightstart;
		print STDOUT "EXCLUDED_REGION=$exclude_string_left $exclude_string_right\n";
		#my $targetlength=($rightstart-$leftstart)-(2*$target_bound);
		#my $targetstart=$leftstart+$target_bound;
		print STDOUT "TARGET=".${$id_exclude{$extprimerid}}[0].",".${$id_exclude{$extprimerid}}[1]."\n";
	}
	print STDOUT "=\n";
	
}
#	check that primer_left and primer_right are initialized!!
#PRINT "="
