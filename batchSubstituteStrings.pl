#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
#arg 1 : mapping file (field 1: old value, field 2: new value), tab-separated
#arg 2 : file where strings are to be sustituted
#arg 3: field number to process in arg2. field separator in arg2 is tab.
my $fieldnumber=$ARGV[2];
open MAP, "$ARGV[0]" or die $!;

my %map=();
while (<MAP>){
	chomp;
	$_=~/(\S+)\t(\S+)$/;
	$map{$1}=$2;
}

#print STDERR Dumper \%map;
close MAP;
open IN, "$ARGV[1]" or die $!;

while (<IN>){
	chomp;
	my @line=split "\t";
	if(exists $map{$line[$fieldnumber-1]}){
		$line[$fieldnumber-1]=$map{$line[$fieldnumber-1]}
	}
	else{
		warn "Couldn't find $line[$fieldnumber-1] in mapping file $ARGV[0]. Left as is.\n";
	print join("\t", @line)."\n";

	}
	print join("\t", @line)."\n";
}
