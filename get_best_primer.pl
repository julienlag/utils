#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use Data::Dumper;

open I, "$ARGV[0]" or die $!;
my %pair_primer_occ;
my %pair_primer_beg_line;
my %pair_primer_end_line;
my %pair_primer_tissues;

while (<I>){
	if( $_=~/^#/){
		next;
		#print STDOUT;
	}
	elsif($_=~/^(\S+)\s\S+\s\d+\s(\S+)/){
		my @line=split "\t";
		push(@{${$pair_primer_tissues{$2}}{$1}}, $line[1]);
		#push(@{${$pair_primer_beg{$2}}{$1}}, $line[0]);
		
		if(exists (${$pair_primer_occ{$2}}{$1})){
			${$pair_primer_occ{$2}}{$1}++;
		}
		else{
			${$pair_primer_occ{$2}}{$1}=1;
			#push(@{${$pair_primer_tissues{$2}}{$1}}, $line[1]);
			push(@{${$pair_primer_end_line{$2}}{$1}}, $line[2], $line[3], $line[4], $line[5], $line[6], $line[7], $line[8], $line[9], $line[10], $line[11], $line[12], $line[13]);
		}
	}
	else{
		die;
	}
}

#print Dumper \%pair_primer_end_line;

foreach my $pair (sort keys %pair_primer_occ){
	foreach my $primer ( sort { ${$pair_primer_occ{$pair}}{$b} <=> ${$pair_primer_occ{$pair}}{$a} } keys %{$pair_primer_occ{$pair}}){
#		print "$pair\t$primer\t${$pair_primer_occ{$pair}}{$primer}\n";
		#foreach my $line (@{${$pair_primer_lines{$pair}}{$primer}}){
		print STDOUT "$primer\t".join(",",@{${$pair_primer_tissues{$pair}}{$primer}})."\t".join("\t",@{${$pair_primer_end_line{$pair}}{$primer}});		#}
		last;#so it stops at best primer
	}
}
