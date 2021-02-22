#!/usr/local/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
use diagnostics;


open VECSCREEN, "$ARGV[0]" or die $!;
open TBL, "$ARGV[1]" or die $!;

my %totrim=();

while(<VECSCREEN>){
	chomp;
	my @line=split "\t";
	for(my $i=1; $i<=$#line;$i++){
		push(@{$totrim{$line[0]}}, $line[$i]-1);
	}

}
#print Dumper \%totrim;
while(<TBL>){
	my @line=split " ";
	if(exists $totrim{$line[0]}){
		#print $line[0]." ";
		my @seq=split("",$line[1]);
		#print $line[0]." ".join("",@seq)."\n";
		#print join(" ",@{$totrim{$line[0]}})."\n";
		for (my $i=0;$i<$#{$totrim{$line[0]}};$i=$i+2){
			#print "i $i ";
			for (my $j=0;$j<=$#seq;$j++){
				#print "j $j ";
				if($j>=${$totrim{$line[0]}}[$i] && $j<=${$totrim{$line[0]}}[$i+1]){
					#print " HIT ";
					$seq[$j]="";
				}
			}
		}
		for (my $i=0;$i<=$#seq;$i++){ 
			if($seq[$i]){
				print STDOUT $line[0]." ".join("",@seq)."\n";
				last;
			}
		}
	}
	else{
		print STDOUT;
	}

}
