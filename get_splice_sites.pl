#!/usr/local/bin/perl -w

use strict;
use warnings;
#use Data::Dumper;
use diagnostics;

# input: file containing half-0-based intron coords in format:
# BF156028        chrY    2766173 2776489 10316
#output: splice sites appended at the end of each line like:
# #seqname        chr     chrStart        chrStop intron_length   donorSeq(unstranded)    acceptorSeq(unstranded)
# BF156028        chrY    2766173 2776489 10316   GT      AG


open INTRONS, "$ARGV[0]" or die $!;
print STDOUT "#seqname\tchr\tchrStart\tchrStop\tintron_length\tdonorSeq(unstranded)\tacceptorSeq(unstranded)\n";
while (<INTRONS>){
	my @line=split "\t";
	chomp;
	next if (exists ($line[4]) && $line[4]<6);
	my $line=$_;
	my $chr=$line[1];
	my $start=$line[2]+1; #corrects for half-0-based coords
	my $startplus1=$start+1;
	my $stop=$line[3];
	my $stopminus1=$stop-1;
	my $donor=`chr_subseq /seq/genomes/H.sapiens/golden_path_200405/chromFa/$chr.fa $start $startplus1`;
	my $acceptor=`chr_subseq /seq/genomes/H.sapiens/golden_path_200405/chromFa/$chr.fa $stopminus1 $stop`;
	chomp $donor;
	$donor=uc($donor);
	$acceptor=uc($acceptor);
	chomp $acceptor;
	print STDOUT "$line\t$donor\t$acceptor\n";
}
