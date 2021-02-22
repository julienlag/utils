#!/usr/bin/env perl

use strict;
use warnings;
use diagnostics;
use Data::Dumper;

my $gff=$ARGV[0];

open GFF, "$gff" or die $!;

while (<GFF>){
	next if $_=~/^#/;
	unless ($_=~/gene_type \"\S+\";/){
		die "No gene_type attribute found at line $., cannot continue.\n";
	}
	$_=~s/("antisense")|("non_coding")|("bidirectional_promoter_lncrna")|("bidirectional_promoter_lncRNA")|("macro_lncRNA")|("lincRNA")|("processed_transcript")|("sense_intronic")|("sense_overlapping")/"lncRNA"/g;
	$_=~s/"\S*pseudogene"/"pseudogene"/g;
	$_=~s/"3prime_overlapping_ncrna"/"misc_RNA"/g;
	$_=~s/"IG_\S*"/"protein_coding"/g;
	$_=~s/"TR_\S*"/"protein_coding"/g ;
	$_=~s/"tRNAscan"/"tRNA"/g;
	print
}
