#!/usr/local/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
use diagnostics;


open F, "grep -v -P \"^#\" $ARGV[0]|" or die $!;

while (<F>){
	my @line=split "\t"; 
	my $id=$line[3]; 
	my $leftseq=$line[14]; 
	my $rightseq=$line[15]; 
	my $leftextprimer=$line[16]; 
	my $leftintprimer=$line[17]; 
	my $rightextprimer=$line[18]; 
	my $rightintprimer=$line[19]; 
	open LEFTSEQ, ">./target_seqs/$id.left.fa" or die $!;
	open RIGHTSEQ, ">./target_seqs/$id.right.fa" or die $!;
	open RIGHTPRIMERS, ">./target_seqs/$id.rightprimers.tbl" or die $!;
	open LEFTPRIMERS, ">./target_seqs/$id.leftprimers.tbl" or die $!;
	my @leftseq=split $leftseq;
	
	#$leftseq=">$id".".left\n$leftseq\n";
	$leftseq=`echo $leftseq| extractseq -auto -filter -osformat2 fasta |descseq -auto -filter -name "$id.left"`;
	#$rightseq=">$id".".right\n$rightseq\n";
	$rightseq=`echo $rightseq| extractseq -auto -filter -osformat2 fasta |descseq -auto -filter -name "$id.right"`;
	$leftextprimer="$id".".leftext $leftextprimer\n";
	$rightextprimer="$id".".rightext $rightextprimer\n";
	$leftintprimer="$id".".leftint $leftintprimer\n";
	$rightintprimer="$id".".rightint $rightintprimer\n";

	print LEFTSEQ $leftseq;
	print RIGHTSEQ $rightseq;
	print RIGHTPRIMERS $rightextprimer;
	print RIGHTPRIMERS $rightintprimer;
	print LEFTPRIMERS $leftextprimer;
	print LEFTPRIMERS $leftintprimer;
	
	close LEFTSEQ;
	close RIGHTSEQ;
	close RIGHTPRIMERS;
	close LEFTPRIMERS;
	
}

