#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use diagnostics;

# reformats NCBI blast's tabular output in order to get query seq length
# first arg is file containing query sequences , fasta format
# 2nd arg is file containing subject sequences , fasta format
# third arg is blast ouput in tab format, with or without comments (e.g. obtained with option -m9)

die "Wrong number of args\n" unless ($#ARGV == 2);

open QUERYFASTA, "FastaToTbl $ARGV[0]|" or die $!;

open BLASTOUT, "$ARGV[2]" or die $!;

my %queryseqlength=();
my %subjectseqlength=();
while(<QUERYFASTA>){
	chomp;
	my @line=split " "; 
	$queryseqlength{$line[0]}=length($line[1])
}
my $db='';
close QUERYFASTA;
open SUBJFASTA, "FastaToTbl $ARGV[1]|" or die $!;
while(<SUBJFASTA>){
	chomp;
	my @line=split " "; 
	$subjectseqlength{$line[0]}=length($line[1])
}

#print Dumper \%queryseqlength;
while(<BLASTOUT>){
	if($_=~/^# Fields: /){
		chomp;
		print $_.", q. length, database, s. length\n";
	}
	elsif($_=~/# Database: (\S+)\n/){
		$db=$1;
		$db=~s/\S+\///g;
		$db=~s/\.fasta//g;
		$db=~s/\.fa//g;
	}
	elsif($_=~/^# /){
		print;
	}
	else{
		chomp;
		my @line=split "\t";
		die "Malformed line, wrong format, cannot continue. Offending line is:\n $_" unless($#line == 11);
		die "$line[0] not found in fasta\n" unless (exists $queryseqlength{$line[0]});
		die "$line[1] not found in fasta\n" unless (exists $subjectseqlength{$line[1]});
		#die "";
		my $qlength=$queryseqlength{$line[0]};
		my $slength=$subjectseqlength{$line[1]};
		print $_."\t$qlength\t$db\t$slength\n";
	}
}
