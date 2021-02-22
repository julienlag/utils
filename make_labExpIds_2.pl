#!/usr/bin/perl -w
use strict;
use warnings;
use lib "/users/rg/jlagarde/julien_utils/";
use Data::Dumper;
use indexFileToHash;
#use Getopt::Long qw(:config debugh);
$|=1;

#that's a hack that works only with Caltech data

my $file=shift;
my %indexFile=indexFileToHash($file);
foreach my $filePath (keys %indexFile){
	my $cell=lc($indexFile{$filePath}{'cell'});
	$cell=ucfirst($cell);
	$cell=~s/[-_.]*//g;
	my $readType="R".$indexFile{$filePath}{'readType'};
	$readType=~s/D*$//g;
	my $insertLength="Il".$indexFile{$filePath}{'insertLength'};
	my $replicate="Rep".$indexFile{$filePath}{'replicate'};
	$indexFile{$filePath}{'labExpId'}=$cell.$readType.$insertLength.$replicate;

	my $outLine="$filePath\t";
	foreach my $attr (sort keys %{$indexFile{$filePath}}){
		$outLine.="$attr=$indexFile{$filePath}{$attr}; "
	}
	$outLine=~s/ $//; #remove trailing space
	$outLine.="\n";
	print $outLine;

}


#print Dumper \%indexFile;
