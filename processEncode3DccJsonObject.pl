#!/usr/bin/env perl


#################
#################
##             ##
##   README    ##
##             ##
#################
#################

##########
### AUTHOR
##########
# Julien Lagarde, CRG, Barcelona. Contact: julienlag@gmail.com

###############
### DESCRIPTION
###############
# This script (processEncode3DccJsonObject.pl) processes ENCODE3 JSON objects through the DCC's REST API. Possible operations are GET, POST and PATCH.

################################
### PREREQUISITES & DEPENDENCIES
################################
## (1) json_xs :
#          the "json_xs" utility should be present somewhere in your $PATH. This is used to output JSON files in a human-readable format ("json-pretty"), in an admittedly inelegant way. Download it from http://search.cpan.org/~mlehmann/JSON-XS-3.01/bin/json_xs. If you don't have json_xs or it's crapping out, just remove the corresponding system calls below

## (2) HTTP::Request CPAN module
## (3) LWP CPAN module

## This script also uses the following "homemade" modules, which will be imported from the $ENCODE3_PERLMODS environment variable (see below):

## (4) getEncode3Object.pm :
#(handles GET requests)

## (5) patchEncode3Object.pm :
# (handles PATCH requests)

## (6) postEncode3Object.pm :
# (handles POST requests)

## (7) prepareEncode3DccConnections.pm :
# (handles API connections and login authentication)

## (8) credentials file:
# encode DCC login credentials are stored in a file referenced in the $ENCODE3_CREDENTIALS_FILE environment variable.
# It should consist of only one line, formatted as follows:
# "$login[space]$password"

#############
### ARGUMENTS
#############
# arg#1: URL to process (to GET, PATCH or POST to)
# arg#2: REST operation to perform ("POST", "PATCH" or "GET")
# arg#3: local JSON file to process (treated as input in case of POST or PATCH, and as ouput in case of GET)
# see usage examples below

#########
### USAGE
#########

## GET examples
# library:
# $ processEncode3DccJsonObject.pl http://test.encodedcc.org/ENCLB035ZZZ/ GET ENCLB035ZZZ.json
# collection:
# $ processEncode3DccJsonObject.pl http://submit.encodedcc.org/biosamples GET all_biosamples.json
## POST example
# library:
# $ processEncode3DccJsonObject.pl http://test.encodedcc.org/libraries/ POST ENCLB035ZZZ.json
## PATCH example
# library:
# $ processEncode3DccJsonObject.pl http://test.encodedcc.org/ENCLB035ZZZ PATCH ENCLB035ZZZ.json

use strict;
use warnings;
use HTTP::Request;
use LWP;
use Data::Dumper;
use JSON;
use lib "/users/rg/jlagarde/julien_utils/";
use lib "$ENV{'ENCODE3_PERLMODS'}";
use processJsonToHash;
use prepareEncode3DccConnections;


# import library of encode3 perl modules from $ENCODE3_PERLMODS environment variable. It should point to the directory where the .pm files are.
# You can set this in your .bashrc by adding the following line to it:
# "export ENCODE3_PERLMODS="/whatever/path/to/encode3/perl_modules/" "
die "Invalid number of args. Should be 3. Exiting.\n" unless ($#ARGV == 2);
my $baseUrl=$ARGV[0];
my $operation=$ARGV[1];
my $jsonFile=$ARGV[2];


if ($operation eq 'GET'){
	use getEncode3Object;
	my $json_text=getEncode3($baseUrl);
	if($json_text=~/{.+}/){ #file is not empty, i.e. could be downloaded
		open OUT, "|json_xs >$jsonFile" or die "$!\n";
		print OUT $json_text;
		close OUT;
	}
}
elsif ($operation eq 'POST'){
	use postEncode3Object;
	open IN, "$jsonFile" or die "$!\n";
	my $whole_json_file='';
	 {
		 local $/;
		 $whole_json_file=<IN>;
	 }
	close IN;
	my $postResponse=postEncode3($baseUrl, $whole_json_file);
	my $jsonResponseFile=$jsonFile.".postResponse.json";
	my $dontOverwriteResponseJson=0;
	if(-f $jsonResponseFile){ # if file already exists and contains file upload credentials, don't overwrite it
		print STDERR "$jsonResponseFile exists\n";
		my $postResponseTree;
		$postResponseTree = processJsonToHash("$jsonResponseFile");
		#print STDERR "blah ".Dumper $postResponseTree;
		if(exists $$postResponseTree{'@graph'}){
			print STDERR "$jsonResponseFile seems to be non-empty\n";
			foreach my $i (@{$$postResponseTree{'@graph'}}){
				if(exists $$i{'upload_credentials'}){
					print STDERR "$jsonResponseFile contains credentials\n";
					$dontOverwriteResponseJson=1;
					last;
				}
			}
		}
		else{
			$dontOverwriteResponseJson=0;
		}
	}
	unless ($dontOverwriteResponseJson){
		print STDERR "$jsonResponseFile seems to be either credentials-empty or malformed, it will be replaced.\n";
open OUT, "|json_xs >$jsonResponseFile" or die "$!\n";
		print OUT $postResponse;
		close OUT;
	}
	else{
		print STDERR "$jsonResponseFile already exists and looks like it contains upload credentials, so it was not overwritten.\n";
	}
}

elsif ($operation eq 'PATCH'){
	use patchEncode3Object;
	open IN, "$jsonFile" or die "$!\n";
	my $whole_json_file='';
	 {
		 local $/;
		 $whole_json_file=<IN>;
	 }
	close IN;
	my $patchResponse=patchEncode3($baseUrl, $whole_json_file);
	my $jsonResponseFile=$jsonFile.".postResponse.json";
	open OUT, "|json_xs >$jsonResponseFile" or die "$!\n";
	print OUT $patchResponse;
	close OUT;
}
else{
	die "Invalid 2nd arg: must be 'POST', 'PATCH' or 'GET'. Exiting.\n";
}


exit 0;
