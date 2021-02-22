#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use diagnostics;

open F1, "cat $ARGV[0] | grep -vP '^#'| awk '{print \$NF}'|" or die $!;

my @file1=<F1>;
print STDERR "scanned file1 done\n";
close F1;

open F2, "cat $ARGV[1] | grep -vP '^#'| awk '{print \$NF}'|" or die $!;

my @file2=<F2>;
close F2;
print STDERR "scanned file2 done\n";

die "The two files don't have the same number of elements." unless ($#file1 == $#file2);

for (my $i=0; $i<=$#file1; $i++){
	chomp $file1[$i];
	chomp $file2[$i];
	print "$file1[$i]\t$file2[$i]\n";
}

#print "FILE 1 @file1\n";
#print "FILE 2 @file2\n";
