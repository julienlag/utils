#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
$|=1;


my $barcodeSeqToIdFile = $ARGV[0];
my %barcodeSeqToId=();
my $blastOutTsv =$ARGV[1];

my $capDesign = $ARGV[2];

open F, "$barcodeSeqToIdFile" or die $!;

while(<F>){
	chomp;
	my @line=split "\t";
	my $barcodeId=$line[0];
	my $barcodeSeq=$line[1];
	push (@{$barcodeSeqToId{$barcodeSeq}},$barcodeId);
}


close F;

open BLAST, "$blastOutTsv" or die $!;

while (<BLAST>){
	chomp;
	my @line = split "\t";
	my $readId=$line[0];
	my $location=$line[1];
	my $barcodeSeq=$line[2];
	my $score=$line[3];
	#my $foundProperBarcode=0;
	my $assignedBarcodeId;
#	print Dumper \@{$barcodeSeqToId{$barcodeSeq}};
	foreach my $barcodeId (@{$barcodeSeqToId{$barcodeSeq}}){
		if ($barcodeId =~ /^$capDesign/ || $barcodeId eq 'UP'){
			$assignedBarcodeId=$barcodeId;
			last;
		}
		else{
			$assignedBarcodeId = $barcodeId unless (defined $assignedBarcodeId)
		}
	}
	push(@line, $assignedBarcodeId);
	print join("\t", @line)."\n";
}