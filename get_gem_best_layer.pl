#!/usr/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
use diagnostics;

open F, "$ARGV[0]" or die $!;


while(<F>){
	chomp;
	my @line=split "\t";
	die "Wrong number of fields" if($#line!=3);
	my $id=$line[0];
	my $seq=$line[1];
	my $mismatchfield=$line[2];
	my $coordfield=$line[3];
	unless($coordfield eq '-'){
		my @mismatches=split (":",$mismatchfield);
		my @hits=split (",",$coordfield);
		
		for (my $i=0;$i<=$#mismatches;$i++){
			if ($mismatches[$i]==0){
				next;
			}
			else{
				print "$id\t$seq\t";
				print join(":", @mismatches[0..$i])."\t";
				print join(",", @hits[0..$mismatches[$i]-1])."\n";
				#for(my $j=0;$j<=$mismatches[$i]-1;$j++){
				#	print "$hits[$j],";
				# }
				last;
			}
		}
	}
}
