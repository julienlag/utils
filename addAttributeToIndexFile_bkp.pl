#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use indexFileToHash;

my $file=shift;
my @attrs=@ARGV;
#remove duplicates from the list of args
my %seen = ();
my @uniq =();
foreach my $item (@attrs) {
    push(@uniq, $item) unless $seen{$item}++;
}
@attrs=@uniq;

foreach my $attr (@attrs){
 die "malformed argument: $attr. Should look like 'key=value'. Cannot continue\n" unless ($attr=~/\S+=\S+/);
 }

my %indexFile=indexFileToHash($file);
#print Dumper \%indexFileCopy;

foreach my $dataFile (sort keys %indexFile){
 foreach my $attr (@attrs){
  $attr=~s/;$//g;
  $attr=~/(\S+)=(\S+)$/;
  my $key=$1;
  my $value=$2;
  $indexFile{$dataFile}{$key}=$value
 }
  print "$dataFile\t";
  my @newAttrs=();
  foreach my $key (sort keys %{$indexFile{$dataFile}}){
   push (@newAttrs, "$key=$indexFile{$dataFile}{$key}");
  }
  print join("; ", @newAttrs).";\n"
}

