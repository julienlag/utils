#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
$|=1;

use lib "/users/rg/jlagarde/julien_utils/";
use gffToHash;

my $gffFile=$ARGV[0];
my $elementAttrid=$ARGV[1]; #MUST uniquely identify a site (e.g. chr1_123456_123456_+)

my %gff=gffToHash($gffFile, $elementAttrid);

#print Dumper \%gff;

foreach my $item (keys %gff){
  my $coverage=$#{$gff{$item}}+1;
	#for (my $j=0; $j<=$#{$gff{$item}};$j++){
	my @outGff=();
	my @attrs;
	for (my $i=0; $i<=7; $i++){ #processing the first 8 GFF fields
	    #print "$gff{$item}[$j][$i]\n";
	    push(@outGff, $gff{$item}[0][$i]);

	  }
	  foreach my $key (keys %{${$gff{$item}[0]}[8]}){
	    push(@attrs, $key." \"${${$gff{$item}[0]}[8]}{$key}\";");
	}
	push (@attrs, "coverage \"$coverage\";");
	my $attr=join(" ", @attrs);
	push(@outGff, $attr);
	print join("\t", @outGff)."\n";
	
}
