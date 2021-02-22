#!/usr/bin/env perl

# needs "transcript" records in input gff


use strict;
use warnings;
use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use gffToHash;
$|=1;
my $locusIdTotranscript_id=$ARGV[0];
my $gffFile=$ARGV[1];
$Data::Dumper::Sortkeys = 1;
my %transcriptCoordsGffHash=gffToHash($ARGV[1], 'transcript_id');

open F, "$locusIdTotranscript_id" or die "$!";

my %locus2transcript=();
while(<F>){
	chomp;
	$_=~/(\S+)\t(\S+)/;
	push (@{$locus2transcript{$1}}, $2);
}
close F;
#print Dumper \%transcriptCoordsGffHash;
print "#locus_id\tlongest5pEndTranscript\tlongest5pEndCoord\tlongest3pEndTranscript\tlongest3pEndCoord\n";
foreach my $locus (keys %locus2transcript){
	my $minStart=10000000000000000; #left boundary of locus
	my $maxEnd=-10; #right boundary of locus
	my $minStartTranscriptid=undef;
	my $maxEndTranscriptid=undef;
	my $locusStrand=undef;
	my $transcriptFoundInGtf=0;
	foreach my $transcript_id (@{$locus2transcript{$locus}}){
		foreach my $transcript_id_GffRecord (@{$transcriptCoordsGffHash{$transcript_id}}){
			#print STDERR "$locus\t${$transcript_id_GffRecord}[2]\n";
			$transcriptFoundInGtf=1;
			$locusStrand=${$transcript_id_GffRecord}[6];
			my $gffStart=${$transcript_id_GffRecord}[3];
			my $gffEnd=${$transcript_id_GffRecord}[4];
			if ($gffStart<$minStart){
				$minStart=$gffStart;
				$minStartTranscriptid=$transcript_id;
			}
			if($gffEnd>$maxEnd){
				$maxEnd=$gffEnd;
				$maxEndTranscriptid=$transcript_id;
			}
		}
	}
	if($transcriptFoundInGtf == 0){
		warn "No transcript found in gff for locus $locus.";
		next;
	}
	if($locusStrand eq '+'){
		print "$locus\t$minStartTranscriptid\t$minStart\t$maxEndTranscriptid\t$maxEnd\n";
	}
	elsif($locusStrand eq '-'){
		print "$locus\t$maxEndTranscriptid\t$maxEnd\t$minStartTranscriptid\t$minStart\n";
	}
	else{
		die "Locus $locus: Strand must be '+' or '-', is '$locusStrand'. Can't continue.\n"
	}
}