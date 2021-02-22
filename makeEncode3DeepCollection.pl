#!/usr/bin/env perl 

use strict;
use warnings;
use HTTP::Request;
use LWP;
use Data::Dumper;
use JSON; 
use lib "$ENV{'ENCODE3_PERLMODS'}"; 
use getEncode3Object;
use prepareEncode3DccConnections;
my $baseUrl=$ARGV[1]; # base url where to fetch the objects

open JSON, "$ARGV[0]" or die $!;
print STDERR "##########\n## Infile is:\n## $ARGV[0]\n##########\n\n";
my $whole_json_file='';
{
        local $/;
        $whole_json_file=<JSON>;
}

my $tree = decode_json($whole_json_file);
my $deepTree;
foreach my $item (@{$$tree{'@graph'}}){
	if(exists ($$item{'accession'})){
		print STDERR $$item{'accession'}."\n";
		my $json_text=getEncode3("$baseUrl/$$item{'accession'}");
		my $json_object=decode_json($json_text);
		push (@{$$deepTree{'@graph'}}, $json_object);
	}
	elsif(exists ($$item{'uuid'})){
		print STDERR $$item{'uuid'}."\n";
		my $json_text=getEncode3("$baseUrl/$$item{'uuid'}");
		my $json_object=decode_json($json_text);
		push (@{$$deepTree{'@graph'}}, $json_object);
	}
	else{
		print STDERR "Current item has no uuid and no accession. Left unchanged.\n";
		push (@{$$deepTree{'@graph'}}, $item);
	}
}

my $outJson=encode_json($deepTree);
print STDOUT "$outJson" ;