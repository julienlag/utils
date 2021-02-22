#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use POSIX;
use processJsonToHash;
use lib "$ENV{'ENCODE3_PERLMODS'}";
use lib "/users/rg/jlagarde/julien_utils/";
use JSON;
my $collectionJsonFile=$ENV{'ENCODE3_FULL_OBJECTS_COLLECTION'};
my $expressionMatrix=$ARGV[0]; #json file
use fetchMetadataFromCollection;

print STDERR "Procesing property lists:";
my %replicateProperties=processPropertiesList("./replicateProperties.list");
my %datasetProperties=processPropertiesList("./datasetProperties.list");
print STDERR " Done.\n";
my %propertiesToOutput=(%replicateProperties, %datasetProperties);
if (-e "./propertiesExcludedFromOutput.list"){
	open F, "./propertiesExcludedFromOutput.list" or die $!;
	while(<F>){
		next unless $_=~/\S+/;
		next if ($_=~/^#/);
		chomp;
		my $line=$_;
		if (exists $propertiesToOutput{$line}){
			delete($propertiesToOutput{$line});
		}
	}
}
my @measures=('tpm', 'fpkm');
foreach my $m (@measures){
	$propertiesToOutput{$m}=1;
}
#make sorted array
my @sortedPropertiesToOutput=();
foreach my $k (sort keys %propertiesToOutput){
	push(@sortedPropertiesToOutput, $k);
}


print STDERR "Converting $expressionMatrix to hash...";
my $expressionMatrixHash;
open JSON, "$expressionMatrix" or die "$expressionMatrix : $!\n";
	my $whole_json_file='';
	{
		local $/;
		$whole_json_file=<JSON>;
	}
	close JSON;
	$expressionMatrixHash = decode_json($whole_json_file);
print STDERR " Done.\n";

#print Dumper $expressionMatrixHash;


#get metadata for datasets (experiments) and corresponding replicates
my %datasetsList=();
my %replicatesList=();
#list of datasets
foreach my $gene (@{$expressionMatrixHash}){
	foreach my $expValues (@{$$gene{'expression_values'}}){
		$datasetsList{$$expValues{'dataset'}}=1;
	}
}

#		foreach my $repUuid ( @{$$fullCollection{$$expValues{'dataset'}}{'replicates'}}){

#print Dumper \%datasetsList;

my $datasetsMetadataHash=fetchMetadataFromCollection(\%datasetsList, \%datasetProperties);
#print Dumper $datasetsMetadataHash;

#get metadata for replicates
foreach my $dataset (keys %{$datasetsMetadataHash}){
	foreach my $rep (split(",",$$datasetsMetadataHash{$dataset}{'replicates'})){
		$replicatesList{$rep}=1;
	}
}

#print Dumper \%replicatesList;
my $replicatesMetadataHash=fetchMetadataFromCollection(\%replicatesList, \%replicateProperties);
#print Dumper $replicatesMetadataHash;

#print STDERR "Converting full metadata collection to hash...";

#my $fullCollection = processJsonToHash($collectionJsonFile);
#print STDERR " Done.\n";

foreach my $gene (@{$expressionMatrixHash}){
	my $outTsv="./tsv/$$gene{'ensembl_id'}.expression.tsv";
	# too slow: `install -D /dev/null ./tsv/$$gene{'ensembl_id'}/$$gene{'ensembl_id'}.expression.tsv`;
	open OUTTSV, ">$outTsv" or die $!;
	print OUTTSV join("\t", @sortedPropertiesToOutput)."\n";
	#print "$$gene{'ensembl_id'}\n";
	foreach my $expValues (@{$$gene{'expression_values'}}){
		#print "\t$$expValues{'dataset'}\n";
		#get replicates ids for dataset
		my %measureValues=();
		for my $measure (@measures){
			my $measuresSum=0;
			my $nrMeasures=0;
			foreach my $repUuid (split(",",$$datasetsMetadataHash{$$expValues{'dataset'}}{'replicates'})){
			#print "\t $repUuid\n";
				my $repNumber=$$replicatesMetadataHash{$repUuid}{'biological_replicate_number'};
				my $measureKeyString="rep$repNumber"."_$measure";
				if (exists ($$expValues{"$measureKeyString"})){
					$measuresSum+=$$expValues{"$measureKeyString"};
					$nrMeasures++;
				}
				else{
					warn "$$gene{'ensembl_id'} / $$expValues{'dataset'} : $measureKeyString not available in expression matrix, skipped.\n";
				}
			}
			my $avgMeasures=$measuresSum/$nrMeasures;
			$measureValues{$measure}=$avgMeasures;
		}

		#populate line with attribute values for datasets and replicates, sort later
		my %line=();
		#dataset metadata
		foreach my $key (keys %{$$datasetsMetadataHash{$$expValues{'dataset'}}}) {
			$line{$key}=$$datasetsMetadataHash{$$expValues{'dataset'}}{$key};
		}
		#replicate metadata (assume all replicate metadata is the same for a given replicate, i.e. extract metadata for only one of them)
		my @repList=split(",",$$datasetsMetadataHash{$$expValues{'dataset'}}{'replicates'});
		my $pickedRepUuid=$repList[0];
		foreach my $key (keys %{$$replicatesMetadataHash{$pickedRepUuid}} ){
			$line{$key}=$$replicatesMetadataHash{$pickedRepUuid}{$key};
		}
		foreach my $m (keys %measureValues){
			$line{$m}=$measureValues{$m};
		}
		my @sortedLine=();
		foreach my $k (@sortedPropertiesToOutput){
			if(exists ($line{$k}) && $line{$k} ne ''){
				push (@sortedLine, $line{$k})
			}
			else{
				push (@sortedLine, 'NA');
			}
		}
		print OUTTSV join("\t", @sortedLine)."\n";
	}
	close OUTTSV;
}



sub processPropertiesList{
	print STDERR " $_[0] ...";
	open PROP, "$_[0]" or die "$_[0]: $!";
	my %properties=();
	while(<PROP>){
		next unless $_=~/\S+/;
		next if ($_=~/^#/);
		chomp;
		my $line=$_;
		$properties{$line}=1;
	}
	close PROP;
	return %properties;
}