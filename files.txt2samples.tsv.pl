#!/usr/bin/perl -w
use strict;
use warnings;
use Spreadsheet::Read;
use Data::Dumper;

#1st arg = infile (files.txt)
#all other args: essential keys to extract and report in outfile


$|=1;
my $infile=shift;
my @essentialKeys=sort { $a cmp $b } @ARGV;
print "#".join("\t", @essentialKeys)."\n";
open F, "$infile" or die $!;
while(<F>){
	#print;
	my $line=$_;
	my @keys=(); 
	my @values=(); 
	chomp; 
	my @line1=split "\t";
	my @line = split (";", $line1[1]);
#	my @linesorted=sort { $a cmp $b } @line ; 
	my %attr=();
	foreach my $j (@essentialKeys){
		my $found=0;
		foreach my $i (@line){
			$i=~s/\s//g; 
			$i=~/(\S+)=(\S+)/; 
			my $key=$1;
			my $value=$2;
			if($key eq $j){
				$found=1;
				$attr{$key}=$value;
			}
		}
		unless ($found==1){
			warn "essential key '$j' not found line $. , set to 'N/A':\n" ;
			$attr{$j}='N/A';
		}
	}
	#print Dumper \%attr;
	my @arrayToPrint=();
	foreach my $key ( sort { $a cmp $b } keys %attr ){
		push (@arrayToPrint, $attr{$key});
	}
	print join("\t",@arrayToPrint)."\n";
	
}
			
#	if($.==1){print "#".join ("\t", @keys)."\n"}; print join ("\t", @values)."\n"; }
