#!/usr/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
use diagnostics;

### input: 
# $ARGV[0] a TBL file containing the transcript sequences (5' to 3', sense) in which to pick RACE primers. can contain Ns, which will be excluded from the allowed design regions
# $ARGV[1] desired size range of amplicons, e.g. "500-700"
# $ARGV[2] is type of RACE ('5p' or '3p')
#this script will suggest a region where to pick RACE primers, excluding 'N' (ambiguous) regions

### output: TSV file
# field 1 = seq ID
# field 2 = start of region (starts at 0)
# field 3 = end of region

die "Didn't understand amplicon range\n" unless ($ARGV[1] =~ /^(\d+)-(\d+)$/);
my $minLength=$1;
my $maxLength=$2;
die "RACE type must be either '5p' or '3p'" unless ($ARGV[2] eq '5p' || $ARGV[2] eq '3p');


print "$minLength $maxLength\n";
