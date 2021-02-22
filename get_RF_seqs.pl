#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use Data::Dumper;

open F, "$ARGV[0]" or die$!;

print STDOUT "#Primer id
#Tissue
#Distance Primer start / RF start
#RF/locus pair id
#Total number of occurrences of RF
#Total number of occurrences of pair (i.e. how many times RF is assigned to locus)
#Number of tissues in which the pair is observed
#Number of different primers from locus l to which RF is assigned
#Assignment Confidence Score
#Internal RF (bool)
#Exonic RF (bool)
#Genic RF (bool)
#Best splice site geneid score
#Best splice site coord
#Seq on 5' side of (RF, SP) pair
#Seq on 3' side of (RF, SP) pair
";

while (<F>){
	
	if(~/^(\S+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\d+)\n/){
		my $primer=$1;
		my $pair=$4;
		my $rfss=$14;
		my $spchr;
        my $spstart;
        my $spstop;
        my $spstrand;
        my $racetype;
		my $spseq;
		my $chr_file;
		my $line=$_;
		chomp $line;
		if($primer=~/^(\S+)_(\d+)_(\d+)_(\S)_primer_(\S+)_(\d+)$/){
			$spchr=$1;
			$chr_file=$spchr.".fa";
			$spstart=$2;
			$spstop=$3;
			$spstrand=$4;
			$racetype=$5;
			if($spstrand eq 'p'){
				$spseq=`chr_subseq $chr_file $spstart $spstop|extractseq -auto -filter -osformat2 raw`;
			}
			else{
				$spseq=`chr_subseq $chr_file $spstart $spstop|revseq -auto -filter -osformat2 raw`;
			}
		}
		else{
			die;
		}
		my $rfchr;
        my $rfstart;
        my $rfstop;
		my $rfseq;
		if($pair=~/^(\S+)_(\d+)_(\d+)_\S+$/){
			$rfchr=$1;
			$rfstart=$2;
			$rfstop=$3;
			if($spstrand eq 'p'){
				if($rfstart>$spstart){
					if($rfss==0){
						$rfss=$rfstart;
					}
					$rfseq=`chr_subseq $chr_file $rfss $rfstop|extractseq -auto -filter -osformat2 raw`;
				}
				else{
					if($rfss==0){
						$rfss=$rfstop;
					}
					$rfseq=`chr_subseq $chr_file $rfstart $rfss|extractseq -auto -filter -osformat2 raw`;
				}
			}
			else{
				if($rfstart>$spstart){
					if($rfss==0){
						$rfss=$rfstart;
					}
					$rfseq=`chr_subseq $chr_file $rfss $rfstop|revseq -auto -filter -osformat2 raw`;
				}
				else{
					if($rfss==0){
						$rfss=$rfstop;
					}
					$rfseq=`chr_subseq $chr_file $rfstart $rfss|revseq -auto -filter -osformat2 raw`;
				}
			}
		}
		else{
			die;
		}
		$spseq=~s/\n//g;
		$rfseq=~s/\n//g;
		if($racetype eq '5race'){
			print STDOUT "$line\t$rfseq\t$spseq\n";
		}
		elsif($racetype eq '3race'){
			print STDOUT "$line\t$spseq\t$rfseq\n";
		}
		else{
			die;
		}

	}
	else{
		die;
	}
}
