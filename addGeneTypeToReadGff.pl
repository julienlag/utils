#!/usr/bin/env perl

use strict;
use warnings;
$|=1;
use Data::Dumper;

my $gffFile=$ARGV[0];
my $genetypesFile=$ARGV[1];

open F, "$genetypesFile" or die $!;

my %genetypes=();
while(<F>){
	chomp;
	my @line=split "\t";
	my @second=split(",", $line[1]);
	foreach my $sec (@second){
		$sec=~s/.+://g;
		$genetypes{$line[0]}{$sec}=1;
	}
	#print STDERR Dumper \%genetypes;

}
close F;
#print Dumper \%genetypes;
open F, "$gffFile" or die $!;

while (<F>){
	chomp;
	my $line=$_;
	$line=~s/\s+$//g;
	my @line=split("\t", $line);
#	my $clusterId=$line[3];
#	my $distance=$line[$#line];
	my @attrs=split(" ", $line[8]);
	my $foundTranscript_id=0;
	my $transcript_id_field;
	for (my $i=0; $i<=$#attrs; $i++){
		if($attrs[$i] eq 'transcript_id'){
			$transcript_id_field=$i+1;
			$foundTranscript_id=1;
			last;
		}
	}
	die "Wrong format, no transcript_id found\n" unless($foundTranscript_id==1);
	my $transcript_id=$attrs[$transcript_id_field];
	$transcript_id=~s/"//g;
	$transcript_id=~s/;//g;
	my $read=$transcript_id;
	my %types=();
	if(exists $genetypes{$read}){
		foreach my $genetype (keys %{$genetypes{$read}}){
			$types{$genetype}=1;
		}
	}
	else{
		print STDERR "$read not found in $genetypesFile, skipped\n";
		next;
	}
	my @types=();
	foreach my $type (sort keys %types){
		push(@types, $type)
	}
	if($#types<1){
		print $line." overlapping_gene_types \"".join(",", @types)."\";\n";
	}
	else{
		print $line." overlapping_gene_types \"multiBiotype\";\n";
	}
}
