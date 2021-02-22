#!/usr/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
use diagnostics;

open F, "$ARGV[0]" or die $!;

$/=">";

while(<F>){
	print "BEGIN- $_ -END\n";
	my @record=split "\n";
	my $header=shift @record;
	print "- $header -\n";
}
