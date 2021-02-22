#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use Data::Dumper;

my $slop=$ARGV[2];
my $maxSize=$ARGV[3];
open GENOME, "$ARGV[1]" or die $!;
my %chr_sizes=();
while(<GENOME>){
	chomp;
	my @line=split "\t";
	$chr_sizes{$line[0]}=$line[1];
}
close GENOME;

open BED, "$ARGV[0]" or die $!;

while(<BED>){
	chomp;
	my $line=$_;
	my @line=split("\t", $line);
	die "Only BED<=6 is supported\n" if($#line>5);
	my $size=$line[2]-$line[1];
	if ($size <= $maxSize){
		unless (exists $chr_sizes{$line[0]}){
			die "$line:\nno chr found in genome file $ARGV[1].\n"
		}
		my $newStart=$line[1]-$slop;
		my $newEnd=$line[2]+$slop;
		if($newStart<0){
			$newStart=0;
		}
		if($newEnd>$chr_sizes{$line[0]}){
			$newEnd=$chr_sizes{$line[0]};
		}
		$line[1]=$newStart;
		$line[2]=$newEnd;
		print join("\t", @line)."\n";
	}
	else{
		print "$line\n"
	}
}