#!/usr/bin/perl -w

### converts this pseudo fastq (decimal quality scores):

# @HANNIBAL_1_FC300WRAAXX:5:1:364:1961
# GGGTCAATGATGTGTTGGCATGTATCATCTGAATCT
# +HANNIBAL_1_FC300WRAAXX:5:1:364:1961
# 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40
# @HANNIBAL_1_FC300WRAAXX:5:1:572:1082
# GTTTGTGATGACTTACATGGAATCTCGTTCGGCTGA
# +HANNIBAL_1_FC300WRAAXX:5:1:572:1082
# 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40

#to real fastq (ascii quality scores)
# @HANNIBAL_1_FC300WRAAXX:5:1:364:1961
# GGGTCAATGATGTGTTGGCATGTATCATCTGAATCT
# +
# hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
# @HANNIBAL_1_FC300WRAAXX:5:1:572:1082
# GTTTGTGATGACTTACATGGAATCTCGTTCGGCTGA
# +
# hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh



use strict;
use warnings;
use diagnostics;
use Data::Dumper;

open FQ, "$ARGV[0]" or die $!;

while (<FQ>){
	if($_=~/^@\S+/){
		print;
		
	}
	elsif($_=~/^\+/){
		print "+\n";
	}
	elsif($_=~/\d+ \d+/){
		chomp;
		my @line=split " ";
		#print Dumper \@line;
		foreach my $decscore (@line){
			$decscore=~ s/-0/0/g;
			unless(chr($decscore+64)){
				die "Doesn't look like solexa decimal quality scores, offending line: $.\n";
			}
			my $asciiscore=chr($decscore+64);
			print $asciiscore;
		}
		print "\n";
	}
	elsif($_=~/[ATGCN]/){
		print;
	}
	else{
		die "line $.\n";
	}
}

