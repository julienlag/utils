#!/usr/local/bin/perl -w

use strict;
use warnings;
use Data::Dumper;
$|=1;
#search for RACE primers having multiple genome matches
#input is output from Paolo's GEM mapping program
#output is "{$seq_id}\n", if seq is considered non unique-in-genome. otherwise EMPTY OUTPUT
open F, "$ARGV[0]" or die $!;

my $orientation=$ARGV[1];
my $nbhitsthreshold=$ARGV[2]; #that's related to the "-p" option of gem-mapper: if number of hits with n mismatches is > p, its details is not reported. we consider these cases as non-unique, regardless of the location of their mismatches
my $mmthreshold=$ARGV[3]; #threshold for number of mismatches
die unless ($orientation eq 'plus' || $orientation eq 'minus');
die unless $nbhitsthreshold;
die unless $mmthreshold;

FLAG1:while (<F>){
	print STDERR $_;
	chomp;
	my @line = split "\t";
	my $seqid= $line[0];
	$seqid=~s/>//g;
	my $seq= $line[1];
	my $seqlength=length($seq);
	print STDERR "length $seqlength\n";
	my @hitslist=split(":", $line[2]);
	if($hitslist[0] == 0){
		print STDERR "ERROR: seq $seqid has no perfect match in genome! Skipped\n";
		next;
	}
	if ($hitslist[0] > 1 || $hitslist[1] > 0 || $hitslist[2] > 0){ # 2x perfect matches, or 1x 1 or 2 mismatches: no need to go any further, oligo is considered non-unique
		print STDOUT "$seqid\n";
		next;
	}
	for(my $i=0; $i<=$#hitslist; $i++){
		if($hitslist[$i]>$nbhitsthreshold){
			print STDOUT "$seqid\n";
		next FLAG1;
		}
	}

	my @hits=split(",", $line[3]);
	for(my $i=1; $i<=$#hits; $i++){
		print STDERR "1 $hits[$i]\n";
		$hits[$i]=~/^\S+:\d+([A-Z]{1}\d{1}.*)*/;
		my $mismatchlist='';
		$mismatchlist=$1 if($1);
		print STDERR "2\t$mismatchlist\n";
		my @mismatchescoords=split(/[A-Z]/, $mismatchlist);
		#print STDERR join(" ", @mismatchescoords)."\n";
		shift @mismatchescoords; #first element is empty string
		my %matchescoords=();
		print STDERR join(" ", @mismatchescoords)."\n";
		if($#mismatchescoords>$mmthreshold-1){ #i.e. the number of mismatches is already too high
			next FLAG1;
		}
		for (my $j=1;$j<=$seqlength;$j++){ #populating @matchescoords, as a complementary of @mismatchescoords
			my $found=0;
			foreach my $item (@mismatchescoords){
				if( $item == $j){
					$found=1;
					last;
				}
			}
			$matchescoords{$j}=$found; # 0 if match, 1 if mismatch
		}
		print STDERR Dumper \%matchescoords;
		if($orientation eq 'plus'){
			if($matchescoords{$seqlength} == 0 && $matchescoords{$seqlength-1} == 0 && $matchescoords{$seqlength-2} == 0){ # 1 match in at least one of the last 3 bases
				print STDOUT "$seqid\n";
				next FLAG1;
			}
		}
		elsif($orientation eq 'minus'){
			if($matchescoords{1} == 0 && $matchescoords{2} == 0 && $matchescoords{3} == 0){ # 1 match in at least one of the first 3 bases
				print STDOUT "$seqid\n";
				next FLAG1;
			}
		}
		else{
			die;
		}
		#print Dumper \%matchescoords;
		
	}
	#print Dumper \%matchescoords;
	#if($orientation eq 'plus'){
	
	
	
	#if($matchescoords[$#matchescoords] == $seqlength || $matchescoords[$#matchescoords-1] == $seqlength-1 || $matchescoords[$#matchescoords-2] == $seqlength-2)  ### check this line carefully
	
	
	
	
	#}
	#elsif($orientation eq 'minus'){
	
	#}
	#else{
	#	die;
	#}
}
#print STDOUT "$seqid\t$seq\t$seqlength\t".join(",", @hits)."\n";

