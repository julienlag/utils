#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use indexFileToHash;
use indexHashToIndexFile;

my %indexFile=indexFileToHash($ARGV[0]);
my $outString=indexHashToIndexFile(\%indexFile);
print $outString;
