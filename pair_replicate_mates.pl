#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use DBI;
use lib "/users/rg/jlagarde/julien_utils/";
use encode_metadata;

# example run:
# pair_replicate_mates.pl all_Gingeras_samples.tsv human cell dataType donorId localization readType rnaExtract seqPlatform protocol>all_Gingeras_human_labExpId_pairs.tsv
# (each pair is represented twice in the output, you shoudl sort|uniq it)

$|=1;

my $labExpId2metadata_file=shift;
my $organism=shift;
my @minSetOfAttributesToToPair=@ARGV;
my %labExpId2metadata=encode_metadata::encode_metadata($labExpId2metadata_file,1,$organism);

foreach my $labExpId1 (sort keys %labExpId2metadata){
	#print "\nLID1=$labExpId1\n";
	foreach my $labExpId2 (keys %labExpId2metadata){
		unless($labExpId1 eq $labExpId2){
			#print "LID2=$labExpId2\n";
			print STDERR "$labExpId1\t$labExpId2\n";
			my $conflict=0;
			foreach my $attr (@minSetOfAttributesToToPair){
				if($labExpId2metadata{$labExpId1}{$attr} eq $labExpId2metadata{$labExpId2}{$attr}){ #&& $labExpId2metadata{$labExpId1}{$attr} ne "N/A"){
					print STDERR "OK $attr: $labExpId2metadata{$labExpId1}{$attr} vs. $labExpId2metadata{$labExpId2}{$attr}\n";
					next;
				}
				else{
					print STDERR "\tNOTOK $attr: $labExpId2metadata{$labExpId1}{$attr} vs. $labExpId2metadata{$labExpId2}{$attr}\n";
					$conflict=1;
					last;
				}
			}
			
			unless($conflict==1){
				if($labExpId1 lt $labExpId2){
					print "$labExpId1\t$labExpId2\n";
				}
				else{
					print "$labExpId2\t$labExpId1\n";
				}
			}
		}
	}
}
