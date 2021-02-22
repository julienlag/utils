#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
$|=1;


#arg1=file1 (BED containing coordinates of clusters, identified in last field:
# chr1    7904981 7904982 chr1_7904981_7904982_+  +
# chr1    8045337 8045345 chr1_8045337_8045345_+;chr1_8045337_8045343_+   +


#arg2=file2 BED containing initial coordinates before rep-clusters:
# chr1    569982  569983  chr1_569982_569983_+    12.000  +


# output is stdout. coordinates and id's of clusters in file 2 are updated based on file1. Other columns in file 1 (including score) are untouched.

open BED1, "$ARGV[0]" or die $!;
open BED2, "$ARGV[1]" or die $!;

my %cluster_coords=();
while(<BED1>){
	chomp;
	my @line=split "\t";
	my @ids=split (";", $line[3]);
	foreach my $id (@ids){
		@{$cluster_coords{$id}}=($line[0],$line[1],$line[2],$line[4]);
	}
}
close BED1;
#print Dumper \%cluster_coords;

while(<BED2>){
	chomp;
	my @line=split "\t";
	print "${$cluster_coords{$line[3]}}[0]\t${$cluster_coords{$line[3]}}[1]\t${$cluster_coords{$line[3]}}[2]\t${$cluster_coords{$line[3]}}[0]_${$cluster_coords{$line[3]}}[1]_${$cluster_coords{$line[3]}}[2]_${$cluster_coords{$line[3]}}[3]\t$line[4]\t${$cluster_coords{$line[3]}}[3]\n"
}
