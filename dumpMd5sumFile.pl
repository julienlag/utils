#!/usr/bin/env perl 

use strict;
use warnings;
use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use indexFileToHash;
use File::Path qw/make_path/;
use File::Basename;
my %index=indexFileToHash($ARGV[0]);

foreach my $file (keys %index){
	$index{$file}{'file.md5sum'}=~s/"//g;
	#print "$file\t$index{$file}{'md5sum'}\n";
	my $md5sumFile=$file.".md5";
	#my @path=split("/", $file);
	my $filebasename=basename($file);
	make_path(dirname($file));
	open MD5SUM, ">$md5sumFile" or die "$md5sumFile : $!\n";
	print MD5SUM"$index{$file}{'file.md5sum'}  $filebasename\n";
	print STDERR "Wrote $md5sumFile\n";
	close MD5SUM;
}
