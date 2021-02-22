#!/usr/bin/perl -w
use strict;
use warnings;
use lib "/users/rg/jlagarde/julien_utils/";
use encode_metadata;
use Data::Dumper;
use Getopt::Long;

$|=1;
my $labExpId2metadata_file="/users/rg/jlagarde/projects/encode/scaling/whole_genome/dcc_submission/samples/all_Gingeras_samples.tsv";
my %labExpId2metadata=encode_metadata::encode_metadata($labExpId2metadata_file);

while(<>){
	chomp;
	$_=~/labExpId=(\S+);/;
	my $labExpIds=$1;
	$_=~/view=(\S+);/;
	my $view=$1;
	my @labExpIds=split(",", $labExpIds);
	foreach my $labExpId (@labExpIds){
		
		unless (exists $labExpId2metadata{$labExpId}){
			warn "Could not find labExpId $labExpId in file $labExpId2metadata_file\n";
			
		}
		else{
			print "$labExpId\t$view";
			foreach my $key (sort keys %{$labExpId2metadata{$labExpId}}){
				print "\t${$labExpId2metadata{$labExpId}}{$key}"
			}
			print "\n";
		}
	}
}
