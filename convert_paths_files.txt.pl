#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use DBI;

my $td=$ARGV[0];
my $file=$ARGV[1];

 open F, "$file" or die $!; 
my $internet="http://genome.crg.es/~jlagarde/";
my $loc="/users/rg/jlagarde/public_html";
$td =~ s/$loc/$internet/g; 
#$string =~ s/\Q$re\E/$rep/og;
#print "$td\n";

while (<F>){
	#print "$td\n"; 
	my $line=$_; 
	$line=~s/\Q$td\E/\./g; 
	print $line
}
