#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use DBI;
use lib "/users/rg/jlagarde/julien_utils/";
use encode_metadata;
$|=1;
my $orig_file=$ARGV[0];
my $new_data=$ARGV[1];

my %labExpId2metadataOrig=encode_metadata::encode_metadata($orig_file,1);
#print Dumper \%labExpId2metadataOrig;
my %labExpId2metadataNew=encode_metadata::encode_metadata($new_data,1);
#print Dumper \%labExpId2metadataNew;

#first get the new list of attributes
my %attributes=();
foreach my $labExpId (keys %labExpId2metadataOrig){
	foreach my $key (keys %{$labExpId2metadataOrig{$labExpId}}){
		$attributes{$key}=1;
		${$labExpId2metadataOrig{$labExpId}}{$key}='N/A' if(!defined (${$labExpId2metadataOrig{$labExpId}}{$key}) || ${$labExpId2metadataOrig{$labExpId}}{$key} eq '');
	}
}
foreach my $labExpId (keys %labExpId2metadataNew){
	print STDERR "$labExpId\n";
	foreach my $key (keys %{$labExpId2metadataNew{$labExpId}}){
		$attributes{$key}=1;
		print STDERR $key." ".Dumper ${$labExpId2metadataNew{$labExpId}}{$key};
		${$labExpId2metadataNew{$labExpId}}{$key}='N/A' if( ! defined (${$labExpId2metadataNew{$labExpId}}{$key}) || ${$labExpId2metadataNew{$labExpId}}{$key} eq '');
	}
}
#put them in an array for easier join print and no need to sort.
my @attrs=();
foreach my $key (sort keys %attributes){
	#print STDERR "$key\n";
	push(@attrs, $key);
}
#print header
print "#".join("\t",@attrs)."\n";

foreach my $labExpId (keys %labExpId2metadataOrig){
	#print STDERR $labExpId." ORIG: ".Dumper $labExpId2metadataOrig{$labExpId};
	#print STDERR $labExpId." NEW: ".Dumper $labExpId2metadataNew{$labExpId};

	my @values=();
	foreach my $key (@attrs){
		if(exists $labExpId2metadataOrig{$labExpId}{$key}){
 			if (exists $labExpId2metadataNew{$labExpId}{$key}){
 				if($labExpId2metadataNew{$labExpId}{$key} ne $labExpId2metadataOrig{$labExpId}{$key}){
 					print STDERR "# DIFF ORIG: $labExpId->$key= $labExpId2metadataOrig{$labExpId}{$key}
# DIFF NEW: $labExpId->$key= $labExpId2metadataNew{$labExpId}{$key}\n";
 					unless ($labExpId2metadataNew{$labExpId}{$key} eq 'N/A'){
 						push (@values,$labExpId2metadataNew{$labExpId}{$key});
 						print STDERR "$labExpId->$key: replaced $labExpId2metadataOrig{$labExpId}{$key} with $labExpId2metadataNew{$labExpId}{$key}\n";
 					}
 					else{
 						print STDERR "$labExpId->$key: keeping $labExpId2metadataOrig{$labExpId}{$key}\n";
						push (@values,$labExpId2metadataOrig{$labExpId}{$key});
 					}
				}
				else{ #i.e. new=orig
					push (@values,$labExpId2metadataOrig{$labExpId}{$key});
				}
			}
			else{ #i.e. no new data exists
				push (@values,$labExpId2metadataOrig{$labExpId}{$key});
			}
		}
		else{ #no orig exists
			if(exists $labExpId2metadataNew{$labExpId}{$key}){
				#use New data
				push (@values,$labExpId2metadataNew{$labExpId}{$key});
			}
			else{ #no orig, no new exists
				push (@values,'N/A');
			}
		}
		
	}
	# 						#check that $#keys == $#values
	die "#attrs ($#attrs) != #values $#values\n" unless ($#attrs == $#values);
	print join("\t",@values)."\n";
}
