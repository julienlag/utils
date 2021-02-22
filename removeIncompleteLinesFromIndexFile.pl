#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use indexFileToHash;
my $file=shift;
my @essential_attrs=@ARGV;

my %indexFile=indexFileToHash($file);

#print Dumper \%indexFile;
open MISSING, ">./skipped.txt";
foreach my $filePath (keys %indexFile){
	my $essAttrNotFound=0;
	foreach my $essAttr (@essential_attrs){
		unless(exists ($indexFile{$filePath}{$essAttr})){
			warn "skipped entry $filePath because '$essAttr' is missing from its attributes. See ./skipped.txt for full list of skipped lines.\n";
			print MISSING "$filePath\t$essAttr\n";
			$essAttrNotFound=1;
			last; #if any fails, end loop and don't print the corresponding line
		}
	}
	next if ($essAttrNotFound==1);
	my $outLine="$filePath\t";
	foreach my $attr (sort keys %{$indexFile{$filePath}}){
		$outLine.="$attr=$indexFile{$filePath}{$attr}; "
	}
	$outLine=~s/ $//; #remove trailing space
	$outLine.="\n";
	print $outLine;
}
close MISSING;
