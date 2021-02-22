#!/usr/local/bin/perl -w

# gets features overlapping encode regions in PSL files, e.g.: perl get_encode.pl blatall.psl_filt_best_or_min0.95.psl ../regions_coords.txt > blatall.psl_filt_best_or_min0.95_encode_only.psl

use strict;
use warnings;
use diagnostics;
use Data::Dumper;


open PSL, "$ARGV[0]" or die $!;
open ENCODE, "$ARGV[1]" or die $!;


my %encode_chr_starts;
my %encode_chr_stops;
while (<ENCODE>){
	if($_=~/^#/){
	   next;
   }
	chomp;
	my @line=split "\t";
	push (@{$encode_chr_starts{$line[1]}}, $line[2]);
	push (@{$encode_chr_stops{$line[1]}}, $line[3]);
}		  
my $overlap_bool;
while (<PSL>){
	$overlap_bool=0;
	my @line=split "\t";
	my $pslline=$_;
	unless($line[0]=~/^\d+$/){ #skips header
		next;
	}
	
	foreach my $chr (keys %encode_chr_starts){
		if($overlap_bool){
			last;
		}
		for (my $i=0; $i<=$#{$encode_chr_starts{$chr}};$i++){
			my $enc_start=${$encode_chr_starts{$chr}}[$i];
			my $enc_stop=${$encode_chr_stops{$chr}}[$i];
			#print STDERR "$line[15],$line[16],$enc_start,$enc_stop,$line[13],$chr,'+','+'\n";
			if(overlap($line[15],$line[16],$enc_start,$enc_stop,$line[13],$chr,'+','+')>0){
				print STDOUT $pslline;
				$overlap_bool=1;
				last;
			}
		}
	}
}



sub overlap{
	my $startlocus1=$_[0];
	my $stoplocus1=$_[1];
	my $startlocus2=$_[2];
	my $stoplocus2=$_[3];
	my $locus1chr=$_[4];
	my $locus2chr=$_[5];
	my $locus1strand=$_[6];
	my $locus2strand=$_[7];
	my $overlap;
	
	#$overlap[0]= 0 if no overlap
	#             1 if locus1 is fully included in locus2  
	#             2 if locus1 3' is inside locus2, but locus1 5' extends locus2 5' 
	#             3 if locus1 5' is inside locus2, but locus1 3' extends locus2 3'
	#             4 if locus2 is fully included in locus1  
	if($locus1chr eq $locus2chr){
		if(($startlocus1<=$stoplocus2 && $startlocus1>=$startlocus2) || ( $stoplocus1<=$stoplocus2 && $stoplocus1>=$startlocus2)){ 
			if(($startlocus1<=$stoplocus2 && $startlocus1>=$startlocus2) && ( $stoplocus1<=$stoplocus2 && $stoplocus1>=$startlocus2)){
				$overlap= 1;
				
			}
			elsif($startlocus1<$startlocus2){
				$overlap=2;
				$overlap=3 if $locus2strand eq '-';
			}
			elsif($stoplocus1>$stoplocus2){
				$overlap=3;
				$overlap=2 if $locus2strand eq '-';
			}
			else{
				die;
			}
		}
		elsif(($startlocus2<=$stoplocus1 && $startlocus2>=$startlocus1) || ( $stoplocus2<=$stoplocus1 && $stoplocus2>=$startlocus1)){ 
			
			if(($startlocus2<=$stoplocus1 && $startlocus2>=$startlocus1) && ( $stoplocus2<=$stoplocus1 && $stoplocus2>=$startlocus1)){
				$overlap= 4;
			}
#		elsif($startlocus2<$startlocus1){
#			push(@overlap,5);
#		}
#		elsif($stoplocus2>$stoplocus1){
#			push(@overlap,6);
#		}
		}
		else{
			$overlap=0;
		}
	}
	else{
		$overlap=0;
	}
	return $overlap;
}
