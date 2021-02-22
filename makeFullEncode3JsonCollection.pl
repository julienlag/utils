#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use utf8;
use JSON;
use diagnostics;
use lib "$ENV{'ENCODE3_PERLMODS'}";
use lib "/users/rg/jlagarde/julien_utils/";
use processJsonToHash;
#my $firstFieldKey='uuid'; # name of the json property to index on
$Data::Dumper::Sortkeys =1;
my $objectToCollectionMapping=$ENV{'ENCODE3_COLLECTIONS_DIR'}."/collections.list"; #correspondence between object name and collection name
my $url=$ARGV[0];

open OBJECT_TO_COLLECTION, "$objectToCollectionMapping" or die "$objectToCollectionMapping: $!";
my %collectionsList;
while(<OBJECT_TO_COLLECTION>){
	next if $_=~/^#/;
	chomp;
	if($_=~/(\S+)\t(\S+)$/){
		$collectionsList{$1}=1;
	}
}
close OBJECT_TO_COLLECTION;
my %fullCollection=();
#my %checkUniqueness=();
foreach my $coll (keys %collectionsList){
	my %collection=();
	my $collectionJsonFile=$ENV{'ENCODE3_COLLECTIONS_DIR'}."/$url/".$coll.".json";
	print STDERR "Converting $collectionJsonFile to hash...";
	$collection{$coll} = processJsonToHash($collectionJsonFile);
	foreach my $entry (@{$collection{$coll}{'@graph'}}){
		if(exists ($$entry{'uuid'})){
			#push(@{$fullCollection{'@graph'}}, $entry);
			if(exists ($fullCollection{$$entry{'uuid'}})){
				warn "WARNING: uuid duplicate $$entry{'uuid'} . Replaced.\n";
			}
			$fullCollection{$$entry{'uuid'}}=$entry;
		}
		else{
			print STDERR "No uuid found for :".Dumper $entry;
		}

		if(exists ($$entry{'accession'})){
			#push(@{$fullCollection{'@graph'}}, $entry);
			if(exists ($fullCollection{$$entry{'accession'}})){
				warn "WARNING: accession duplicate $$entry{'accession'} . Replaced.\n";
			}
			$fullCollection{$$entry{'accession'}}=$entry;
		}
		if(exists ($$entry{'aliases'})) {
			foreach my $alias (@{$$entry{'aliases'}}) {
			#push(@{$fullCollection{'@graph'}}, $entry);
				if(exists ($fullCollection{$alias})){
					warn "WARNING: alias duplicate $alias . Replaced.\n";
				}
				$fullCollection{$alias}=$entry;
			}
		}
		if(exists ($$entry{'@id'})) {
			if(exists ($fullCollection{$$entry{'@id'}})){
				warn "WARNING: id duplicate $$entry{'\@id'} . Replaced.\n";
			}
			$fullCollection{$$entry{'@id'}}=$entry;
		}

	}

	print STDERR " Done.\n";
}

#print Dumper \%fullCollection;
my $outJson=encode_json(\%fullCollection);

print $outJson;
