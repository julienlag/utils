#!/usr/bin/perl -w
use strict;
use warnings;
use lib "/users/rg/jlagarde/julien_utils/";
use Data::Dumper;
use indexFileToHash;
$|=1;

my $file=shift;
my %indexFile=indexFileToHash($file);
foreach my $filePath (keys %indexFile){
	my $outLine="$filePath\t";
	foreach my $attr (sort keys %{$indexFile{$filePath}}){
		$outLine.="$attr=$indexFile{$filePath}{$attr}; "
	}
	$outLine=~s/ $//; #remove trailing space
	$outLine.="\n";
	print $outLine;
}
