#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use gffToHash;

$|=1;

my $gffFile1=shift;
my $gffFile2=shift;
my $idrFile=shift;
my $measureFile=shift; #in "matchedPeaks" format
my $elementAttrid=shift; #e.g. "exon_id"
my $measure=shift; #e.g."RPKM"
my @attrToMerge=@ARGV;
my %attrToMerge=();
foreach my $i (@attrToMerge){
	$attrToMerge{$i}=1
}
open I, "$idrFile" or die $!;
open M, "$measureFile" or die $!;
#open G1, "$gffFile1" or die $!;
#open G2, "$gffFile2" or die $!;

my %id2idr=();
my %id2measure1=();
my %id2measure2=();
while(<I>){
	chomp;
	my @line=split "\t";
	$id2idr{$line[1]}=$line[0];
}

close I;

while(<M>){
	chomp;
	my @line=split "\t";
	die "fields 1 and 3 shoudl contain the same string.\n" unless ($line[0] eq $line[2]);
	$id2measure1{$line[0]}=$line[1];
	$id2measure2{$line[0]}=$line[3];
}
close M;


my %gff1=gffToHash($gffFile1, $elementAttrid);
my %gff2=gffToHash($gffFile2, $elementAttrid);



foreach my $item (keys %gff1){
	for (my $j=0; $j<=$#{$gff1{$item}};$j++){
		my @outGff=();
		my @attrs;
#		print STDERR "gff1 $j:".Dumper \@{$gff1{$item}};
#		print STDERR "gff2 $j:".Dumper \@{$gff2{$item}};

		for (my $i=0; $i<=7; $i++){ #processing the first 8 GFF fields
			if( $gff1{$item}[$j][$i] ne $gff2{$item}[$j][$i]){
				my $field=$i+1;
				warn "Properties of '$item' differ in file1 and file2 (field $field, '$gff1{$item}[$j][$i]' vs '$gff2{$item}[$j][$i]'. Will output $gff1{$item}[$j][$i]. \n";
			}
			push(@outGff, $gff1{$item}[$j][$i]);
		}
		foreach my $key (keys %{${$gff1{$item}[$j]}[8]}){ #processing GFF attributes (9th field)
			my $isToMerge=0;
			#foreach my $i (@attrToMerge){ #check if the 2 values of the attribute can be merged
			if(exists $attrToMerge{$key}){
				$isToMerge=1;
			}
			#}
			if($isToMerge==0){
				#if(${${$gff1{$item}}[8]}{$key} ne ${${$gff2{$item}}[8]}{$key}){ 
				push(@attrs, $key."1 \"${${$gff1{$item}[$j]}[8]}{$key}\";");
				push(@attrs, $key."2 \"${${$gff2{$item}[$j]}[8]}{$key}\";");
				#}
			}
			else{
				push(@attrs, $key." \"${${$gff1{$item}[$j]}[8]}{$key}\";");
#				                    \"${${$gff2{$item}[$j]}[8]}{$key}\"
				if(${${$gff1{$item}[$j]}[8]}{$key} ne ${${$gff2{$item}[$j]}[8]}{$key}){ 
					warn "$item: $key value differ in two files ${${$gff1{$item}[$j]}[8]}{$key}  ${${$gff2{$item}[$j]}[8]}{$key}. Keeping what's in file1.\n";
				}
			}
		}
		#print STDERR "$item\n";
		$id2idr{$item}="NA" unless(exists $id2idr{$item});
		push (@attrs, "iIDR \"$id2idr{$item}\";");
		my $attr=join(" ", @attrs);
		push(@outGff, $attr);
		print join("\t", @outGff)."\n";
	}
}
