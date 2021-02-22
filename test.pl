#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Data::Dumper;

#use Devel::Size qw(size total_size);


my @a=('1','2','3','4','5');

foreach my $i (@a, '6'){
	print "$i\n";
}

print "\n".scalar(@a)."\n"