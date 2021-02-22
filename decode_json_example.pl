#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
$|=1;
use JSON;


open JSON, "$ARGV[0]" or die $!;
my $whole_json_file='';
{
	local $/;
	$whole_json_file=<JSON>
}


#print $whole_json_file;

my $tree = decode_json($whole_json_file);
print Dumper $tree;
#traverse the hash to convert all instances of booleans (represented as objects in perl) to proper 'true'and 'false' strings




foreach my $lib (@{$$tree{'@graph'}}){
	foreach my $attr (keys %$lib){
		print "$attr=$$lib{$attr}\n";
	}
}



















#use JSON::PP; 

# my $file = $ARGV[0];
# my $data;

# if (open (my $json_stream, $file))
# {
#       local $/ = undef;
#       my $json = JSON::PP->new;
#       $data = $json->decode(<$json_stream>);
#       close($json_stream);
# 	  print Dumper $data;
# }
