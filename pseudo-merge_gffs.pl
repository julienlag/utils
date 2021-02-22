#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
$|=1;


#arg1=file1
#arg2=file2
#arg3=element id to report (e.g. "transcript_id" value in 9th field)
#arg4=measure to report (e.g. "RPKM" value in 9th field). 

# output is 2 files containing the union of the two GFF files. i.e. the 2 outputs contain the same elements (as identified by $elementAttrid)

open GFF1, "$ARGV[0]" or die $!;
open GFF2, "$ARGV[1]" or die $!;


my $elementAttrid=$ARGV[2];
my $measure=$ARGV[3];
my %elements1=();
my %elements2=();
my %elements1and2=(); #to account for elements absent from either of the two files

while(<GFF1>){
	chomp;
	my $line=$_;
	my@arr=parse_gff($_);
	#print "@arr\n";
	$elements1{$arr[0]}=$line;
	$line=~s/$measure (\S+);//g;
	$line=~s/\s+$//g;
	$elements1and2{$arr[0]}=$line;
}
while (<GFF2>){
	chomp;
	my $line=$_;
	my @arr=parse_gff($_);
	#print "@arr\n";
	$elements2{$arr[0]}=$line;;
	$line=~s/$measure (\S+);//g;
	$line=~s/\s+$//g;
	$elements1and2{$arr[0]}=$line;
}

#print Dumper \%elements1and2;

my $out1=$ARGV[0].".fullset.gff";
my $out2=$ARGV[1].".fullset.gff";

open OUT1, "|sort -k1,1 -k4,4n -k5,5n >$out1" or die $!;
open OUT2, "|sort -k1,1 -k4,4n -k5,5n >$out2" or die $!;

foreach my $id (keys %elements1and2){
	if(exists $elements1{$id}){
		print OUT1 "$elements1{$id}\n";
	}
	else{
		print OUT1 "$elements1and2{$id} $measure \"0\";\n";
	}
	if(exists $elements2{$id}){
		print OUT2 "$elements2{$id}\n";
	}
	else{
		print OUT2 "$elements1and2{$id} $measure \"0\";\n";
	}	

}

sub parse_gff{
	#chomp $_[0];
	$_[0]=~s/\"//g;
	$_[0]=~s/;//g;
	my $elementid=undef;
	my $value=undef;
	if($_[0]=~/\s$elementAttrid (\S+)/){
		$elementid=$1;
		#$elementid=~s/\"//g;
	}
	else{
		die "$elementAttrid attribute not found in line $.. Cannot continue\n";
	}
	if ($_[0]=~/\s$measure (\S+)/){
		$value=$1;
	}
	else{
		die "$measure attribute not found in line $.. Cannot continue\n";
	}
	return ($elementid, $value)
}
