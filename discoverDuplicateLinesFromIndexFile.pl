#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use indexFileToHash;
use Storable qw(dclone); 

my $file=shift;
my @unique_attr_tuples=@ARGV;
#remove duplicates from the list of args
my %seen = ();
my @uniq =();
foreach my $item (@unique_attr_tuples) {
    push(@uniq, $item) unless $seen{$item}++;
}
@unique_attr_tuples=@uniq;

my %indexFile=indexFileToHash($file);
my %indexFileCopy= %{ dclone(\%indexFile)};

#print Dumper \%indexFileCopy;
my %duplicateAlreadySeen=(); #this is meant to output pairs of duplicates only once (and not "A = B" then "B = A")
#my %attributeSeenInIndexFile=(); # to avoi dtypos in arguments
foreach my $dataFile1 (sort keys %indexFile){
	#print $dataFile1;
	next if (exists($duplicateAlreadySeen{$dataFile1}));
	my %duplicates=();
	foreach my $dataFile2 (keys %indexFileCopy){
#		print "$dataFile1 vs $dataFile2\n";
		next if($dataFile1 eq $dataFile2);
		my $sameMetadata=0;
		for (my $i=0; $i<=$#unique_attr_tuples;$i++){
			my $attr=$unique_attr_tuples[$i];
			if(exists($indexFile{$dataFile1}{$attr}) && exists($indexFileCopy{$dataFile2}{$attr})){ #attr is defined for both files
#			print "\n$attr\n'$indexFile{$dataFile1}{$attr}'\t'$indexFileCopy{$dataFile2}{$attr}'\n";
				#$attributeSeenInIndexFile{$attr}=1;
				last unless (  $indexFile{$dataFile1}{$attr} eq $indexFileCopy{$dataFile2}{$attr}); #end loop if current attr has different value in both hashes
			}
			elsif(!exists($indexFile{$dataFile1}{$attr}) xor !exists($indexFileCopy{$dataFile2}{$attr})){ #only one attr is defined: the two items are considered DIFFERENT -> end for loop.
				#$attributeSeenInIndexFile{$attr}=1;
				last;
			}
			#elsif(exists($indexFile{$dataFile1}{$attr}) && exists($indexFileCopy{$dataFile2}{$attr})){
				
			#}
			if($i==$#unique_attr_tuples){ #reached last attr
				$sameMetadata=1;
				$duplicateAlreadySeen{$dataFile2}=1;
			}
		}
		if($sameMetadata==1){
			$duplicates{$dataFile1}=1;
			$duplicates{$dataFile2}=1;
		}
	}
	my @dups=(); #only there to print
	foreach my $dup (sort keys %duplicates){
		push(@dups, $dup);
	}
	if($#dups>0){
		print STDERR join("\n", @dups)."\n=\n";
	}
}
