#!/usr/bin/perl -w
use strict;
use warnings;
use Spreadsheet::Read;
use Data::Dumper;

#converts to TSV a worksheet named $ARGV[1] inside an ODS spreadsheet named $ARGV[0]
#messages in STDERR  like:
# "Use of uninitialized value in join or string at /software/FC12-x86_64/general/perl-5.10.1/lib/site_perl/5.10.1/Spreadsheet/ReadSXC.pm line 198."
# don't seem to be very important

$|=1;
my $odsFilename=$ARGV[0];
my $worksheet=$ARGV[1];

my $ref = ReadData ("$odsFilename", strip=>3) or die $!;
print STDERR "Spreadsheet is:\n". Dumper \$ref->[0];
die "Could not find worksheet named '$worksheet' in spreadsheet" unless exists $ref->[0]{sheet}{"$worksheet"}; #verify that the worksheet exists
#my %sheet = %{$ref->[$ref->[0]{sheet}{"$worksheet"}]};
#my $doc = odf_document->get($ARGV[0]) or die $!; 
#my $sheet = $doc->get_body->get_table("$ARGV[1]") or die "Could not find table named '$ARGV[1]'";
#print "ref =\n". Dumper \$ref;
my $lastRow=${$ref->[$ref->[0]{sheet}{"$worksheet"}]}{maxrow};
print STDERR "last row: $lastRow\n";
#print "sheet =\n".Dumper \%sheet;

print "#"; #to comment out header (i assume it's in the first row)

for (my $i=1;$i<=$lastRow;$i++){
	my $row=$i;
	my @row = Spreadsheet::Read::row ($ref->[$ref->[0]{sheet}{"$worksheet"}], $row);
	foreach my $cell (@row){
		$cell = '' unless (defined ($cell));
	}
	print join("\t", @row)."\n";
}
