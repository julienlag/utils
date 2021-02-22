#!/usr/bin/env perl

#for each feature in fileA, report features in fileB that overlap it, and their 3' and 5' end distances
#one line output per overlap, consisting of:
# fileA_record\tfileB_record\toverlap_class\toverlap_5pdist\toverlap_3pdist
use strict;
use warnings;
#use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use gffToHash;
use overlap;
$|=1;
my $fileA=$ARGV[0];
my $fileB=$ARGV[1];
my $stranded_comparison=1;
if(exists ($ARGV[2]) ){
	$stranded_comparison=$ARGV[2];
}
die "Stranded or not? (Arg #3, possible values: '0' (unstranded), '1' (same strand only) or '2' (different strand only).\n" unless ($stranded_comparison == 0 || $stranded_comparison == 1 || $stranded_comparison == 2);

my %fileAGffHash=gffToHash($fileA, 'transcript_id',1);
my %fileBGffHash=gffToHash($fileB, 'transcript_id',1);

#print "###fileA:". Dumper \%fileAGffHash;
#print "###fileB:". Dumper \%fileBGffHash;

foreach my $locusA_id (keys %fileAGffHash){
	foreach my $locusA_record (@{$fileAGffHash{$locusA_id}}){
		my $locusA_chr=${$locusA_record}[0];
		my $locusA_start=${$locusA_record}[3];
		my $locusA_end=${$locusA_record}[4];
		my $locusA_strand=${$locusA_record}[6];
		my $locusA_line=${$locusA_record}[9];
		#print STDERR "$locusA_chr $locusA_start\n";
		foreach my $locusB_id (keys %fileBGffHash){
			foreach my $locusB_record (@{$fileBGffHash{$locusB_id}}){
				my $locusB_chr=${$locusB_record}[0];
				my $locusB_start=${$locusB_record}[3];
				my $locusB_end=${$locusB_record}[4];
				my $locusB_strand=${$locusB_record}[6];
				my $locusB_line=${$locusB_record}[9];
				my @overlap=();
				if($stranded_comparison ==1){
					#the overlap() subroutine natively does stranded comparisons only
					@overlap=overlap::overlap($locusA_start,$locusA_end,$locusB_start,$locusB_end,$locusA_chr,$locusB_chr,$locusA_strand,$locusB_strand);
				}
				elsif($stranded_comparison == 0){
					#the overlap() subroutine natively does stranded comparisons only, so we need to trick it
					@overlap=overlap::overlap($locusA_start,$locusA_end,$locusB_start,$locusB_end,$locusA_chr,$locusB_chr,'+','+');
				}
				elsif($stranded_comparison == 2){
					#the overlap() subroutine natively does stranded comparisons only, so we need to trick it
					if($locusA_strand ne $locusB_strand){
						@overlap=overlap::overlap($locusA_start,$locusA_end,$locusB_start,$locusB_end,$locusA_chr,$locusB_chr,'+','+');
					}
					else{
						$overlap[0]=0;
					}
				}
				else{
					die;
				}
				if($overlap[0] > 0){ #there is some kind of overlap
					print "$locusA_line\t$locusB_line\t".join("\t", @overlap)."\n";
				}
			}
		}
	}
#}
}