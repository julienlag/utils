#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use indexFileToHash;
my $file=shift;

my %indexFile=indexFileToHash($file);

#print Dumper \%indexFile;

foreach my $filePath (keys %indexFile){
	$filePath=
	my $outLine="$filePath\t";
	foreach my $attr (sort keys %{$indexFile{$filePath}}){
		$outLine.="$attr=$indexFile{$filePath}{$attr}; "
	}
	$outLine=~s/ $//; #remove trailing space
	$outLine.="\n";
	print $outLine;
}
