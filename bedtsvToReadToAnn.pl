#!/usr/bin/env perl

use strict;
use warnings;
$|=1;
use Data::Dumper;

my %readTogeneIdAndType=();
while(<STDIN>){
	my @line=split "\t";
#	if($line[$#line]>0){ #it does overlap something !! this doesn't work because of a bedtools bug ('0' returned even though there is an overlap)
	if($line[12] ne '.'){ #it does overlap something

		$line[20]=~/gene_id \"(\S+)\";/;
		my $geneid=$1;
		$line[20]=~/gene_type \"(\S+)\";/;
		my $genetype=$1;
		$readTogeneIdAndType{$line[3]}{"$geneid:$genetype"}=1;
	}
	else{ #intergenic
		$readTogeneIdAndType{$line[3]}{"NA:nonExonic"}=1;

	}
}


#print Dumper \%readTogeneIdAndType;

foreach my $read (keys %readTogeneIdAndType){
	print "$read\t";
	my @tmp=();
	foreach my $overlap (keys %{$readTogeneIdAndType{$read}}){
		push (@tmp, $overlap);
	}
	print join(",",@tmp)."\n";
}
