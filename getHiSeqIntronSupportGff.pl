#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

my $ipsaOutput=$ARGV[0];
my $gff=$ARGV[1];
open IPSA, "$ipsaOutput" or die $!;

my %ipsaSupport=();
while(<IPSA>){
	chomp;
	my @line=split "\t";
	$ipsaSupport{$line[0]}=$line[1];
}
close IPSA;

open GFF, "$gff" or die $!;

while(<GFF>){
	chomp;
	my $line=$_;
	$line=~ s/\s+$//;
	my @line=split("\t", $line);
	my $ipsaStart=$line[3]-1;
	my $ipsaEnd=$line[4]+1;
	my $intronId=$line[0]."_".$ipsaStart."_".$ipsaEnd."_".$line[6];
	my $intronSupport=0;
	if(exists $ipsaSupport{$intronId}){
		$intronSupport=$ipsaSupport{$intronId};
	}
	print "$line hiSeqSjReadSupport \"$intronSupport\";\n";

}