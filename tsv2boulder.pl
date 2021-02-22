#!/usr/local/bin/perl -w

use warnings;
use strict;
use Data::Dumper;

open TSV, "grep -v -P \"^#\" $ARGV[0]|" or die $!;
#my $bound=$ARGV[2];
my $out_center=$ARGV[0]."center.tsv";
my $tblfile=$ARGV[0].".tbl";
open PRIMERSPCOORDS, "$ARGV[1]", or die $!;
open CENTER, ">$out_center" or die $!;
open TBL, ">$tblfile" or die $!;
my %primer_spcoords;

while (<PRIMERSPCOORDS>){
	chomp;
	my @line=split "\t";
	push(@{$primer_spcoords{$line[0]}}, $line[1], $line[2]);
}

#print Dumper \%primer_spcoords;


while (<TSV>){
	chomp;
        my @line= split "\t";
        #my $geneid=$line[0];
        my $pairid=$line[3];
		my $primer=$line[0];
		$primer=~/\S+_\d+_\d+_\S{1}_primer_(\d{1})race_\d+$/;
		my $race=$1;
		my $primerspstart=${$primer_spcoords{$primer}}[0];
		my $primerspstop=${$primer_spcoords{$primer}}[1];
		my $primerlength=$primerspstop-$primerspstart;
        #my $index_primer_seq=$line[1];
        #my $leftid=$line[2];
        my $leftseq=$line[14];
        my $rightseq=$line[15];
		chomp $rightseq;
        #my $index_primer_seq_length=length($index_primer_seq);
        my $rightseqlength=length($rightseq);
        my $leftseqlength=length($leftseq);
        my $fullseqlength=$rightseqlength+$leftseqlength;
		my $target_start;
		my $target_length;
		#my $force_right_start;
		my $force_left_incl_region_start;
		my $force_incl_region_length;
		my $left_excl_region_start;
		my $left_excl_region_length;
		my $right_excl_region_start;
		my $right_excl_region_length;
		#my $force_right_length;
		#my $force_left_length;
		if($race==5){
			$target_start=$leftseqlength-20;
			$target_length=32;
			#$force_right_start=$leftseqlength+$primerspstart;
			
			#$force_right_length=$primerlength;
			$force_left_incl_region_start=$leftseqlength-120;
			$force_incl_region_length=($leftseqlength+$primerspstop)-$force_left_incl_region_start;
			$left_excl_region_start=$force_left_incl_region_start+40;
			$left_excl_region_length=$target_start-$left_excl_region_start;
			#if($left_excl_region_length<0){
				
			#}
			$right_excl_region_start=$target_start+$target_length;
			$right_excl_region_length=$primerspstart-$right_excl_region_start;
			#$force_left_length=32;
		}
		elsif($race==3){
			$target_start=$leftseqlength-10;
			$target_length=32;
			$force_left_incl_region_start=$primerspstart;
			$force_incl_region_length=($leftseqlength+120)-$primerspstart;
			$left_excl_region_start=$primerspstop;
			$left_excl_region_length=($leftseqlength-10)-$primerspstop;
			$right_excl_region_start=$leftseqlength+32;
			$right_excl_region_length=($leftseqlength+110-40)-$right_excl_region_start;
			#$force_right_start=$leftseqlength+80;
			#$force_right_length=32;
			#$force_left_start=$primerspstart;
			#$force_left_length=$primerlength;
		}
		else{
			die "Unknown RACE type\n";
		}
		if($force_left_incl_region_start<0){
			warn "$pairid\tLeft seq too short, skipped\n";
			next;
		}
		#if($>$fullseqlength){
		#	warn "$pairid\tRight seq too short, skipped\n";
		#	next;
		#}

        print CENTER "$pairid\t$target_start,$target_length\n";
        print TBL "$pairid $leftseq$rightseq\n";
        #if($targetstart>$target_start){
        #        warn "$pairid: TARGET start provided > center to exclude. Skipped\n";
        #        #$targetstart=$target_start;
		#		next;
        #}
        #my $targetlength=$fullseqlength-(2*$bound);
        #if($targetlength+$targetstart<$target_start+$target_length){
        #        warn "TARGET end provided < center end to exclude for $pairid\n";
        #        #$targetlength=($target_start+$target_length)-$targetstart;
		#		next;
        #}
        #my $leftincl_region_length=$targetstart-1;
        print STDOUT "$pairid\tTARGET=$target_start,$target_length\n";
		print STDOUT "$pairid\tINCLUDED_REGION=$force_left_incl_region_start,$force_incl_region_length\n";
        print STDOUT "$pairid\tEXCLUDED_REGION=$left_excl_region_start,$left_excl_region_length $right_excl_region_start,$right_excl_region_length\n";
}








