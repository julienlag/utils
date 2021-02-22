#!/usr/bin/env perl 


use strict;
use warnings;
use Data::Dumper;
#use HTTP::Request;
#use LWP;
use JSON; # try to use JSON::XS instead, it's cleaner
#use lib "$ENV{'ENCODE3_PERLMODS'}";

open JSON, "$ARGV[0]" or die $!;
my $whole_json_file='';
{
        local $/;
        $whole_json_file=<JSON>
}

my $tree = decode_json($whole_json_file);
#print Dumper $tree;

#foreach my $repObject (@{\$tree{'@graph'}}){
#  print $repObject{'experiment'};
#}
#print "#labExpId\treplicate\tdccExpAcc\n";
foreach my $lib (@{$$tree{'@graph'}}){
  if ( (exists ($$lib{'library'}{'accession'})) && (exists ($$lib{'biological_replicate_number'})) && (exists ($$lib{'experiment'})) && (exists ($$lib{'technical_replicate_number'})) ){
  print $$lib{'library'}{'accession'}."\t";
  print $$lib{'biological_replicate_number'}."\t";# if exists ($$lib{'library.accession'});
  $$lib{'experiment'}=~/\/experiments\/(\S+)\//;
  my $dccExpAcc=$1;
  print $dccExpAcc."\t";
  print $$lib{'technical_replicate_number'}."\n";# if exists ($$lib{'library.accession'});

  }
}
#        foreach my $attr (keys %$lib){
#                print "$attr=$$lib{$attr}\n";
#        }
#}


exit 0;
