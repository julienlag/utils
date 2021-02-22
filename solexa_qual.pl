#!/usr/bin/perl -w

### dumps avg quality score in decimal values for each read (one line per read) in a FASTQ file
### input fastq file must contain Solexa quality score in ASCII fromat


use strict;
use warnings;
use diagnostics;

open FQ, "$ARGV[0]" or die $!;




#my $startrecord=0;
my $inrecord=0;
my $checkformat=0;
while (<FQ>){
	#if($_=~/^@/){
	#	$startrecord=1;
	#	next;
	#}
	if($_=~/^@/){
		chomp;
		print;
	}
	if($_=~/^\+$/){
		$inrecord=1;
		#print;
		$checkformat=1;
		next;
	}
	if($inrecord){
		#print;
		chomp;
		my @line=split "";
		my @decvalues=();
		foreach my $char (@line){
			unless(ord($char)){
				die "Doesn't look like solexa ascii quality scores, offending line: $.\n";
			}
			#my $decvalue=$ascii{$char}-64;
			my $decvalue=ord($char)-64;

			push(@decvalues, $decvalue);
			
		}
		my $sum=0;
		foreach my $value (@decvalues){
			$sum+=$value;
		}
		my $avg=sprintf("%.1f",$sum/($#decvalues+1));
		print "\t$avg\t";
		#print join(" ", @decvalues);
		print "\n";
		$inrecord=0;
		next;
	}

}
	die "Not in FASTQ format\n" unless ($checkformat==1);
