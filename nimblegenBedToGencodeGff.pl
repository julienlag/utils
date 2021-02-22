#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use gffToHash;
$|=1;



my $id_mapping_file=$ARGV[0];
my $nimblegen_bed_file=$ARGV[1];

open F, "$id_mapping_file" or die $!;

my %nimblegenToTrid=();

while (<F>){
	chomp;
	$_=~/(\S+)\t(\S+)$/;
	$nimblegenToTrid{$2}=$1;
}

close F;

open F, "$nimblegen_bed_file" or die $!;

while(<F>){
	chomp;
	next if($_=~/^track/);
	my @line=split "\t";
	$line[1]+=1; #convert to gff coord system
	print "$nimblegenToTrid{$line[0]}\tprobe\tprobe\t$line[1]\t$line[2]\t.\t+\t.\ttranscript_id \"$nimblegenToTrid{$line[0]}.$line[1].$line[2]\";\n";
#ENST00000445427.1       Primer    Primer    639     665     .       +       .       transcript_id ENST00000445427.1.3p.686;
}