#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use gffToHash;
use overlap;
$|=1;
# comptr from Sarah compares transcripts in two gff files only at the intron level.
# It outputs the following categories (here taking the example of 'phase4' (aka 'assessed'/'ass') vs. 'genc7' (aka 'reference'/'ref') gff comparison):
#
# - Exact: there is a genc7 transcript with all its introns equal to the phase4 transcript and reciprocally
# - Extension: there is a genc7 transcript with all its introns having an equivalent in some phase4 transcript, but the latter has extra introns
# - Inclusion: all introns in the phase4 transcript have an equivalent in some genc7 transcript, but the latter has extra introns
# - Overlap: there is a genc7 transcript overlapping the phase4 transcript
# - Intergenic_or_antisense: the phase4 transcript is stranded and spliced but does not "strandedly" overlap any genc7 transcript
# - Monoexonic: the phase4 transcript is mono-exonic (no comparison to genc7 made)
#
#
# Exact, Extension, Inclusion, Overlap entries will be sub-categorized
die "Takes 4 args. Cannot continue\n" unless ($#ARGV==3);
my $comptrOut=$ARGV[0];
my $assessedGff=$ARGV[1];
my $refGff=$ARGV[2];
#my $outputAll=1; # outputs all (sense, non-monoexonic) overlapping reference transcripts found (default). This means that a given assessed transcript_id (column 1) might be present in multiple lines.
# When set to 0, output only one reference transcript per assessed transcript. In case of conflict the one reference transcript will be chosen based
my $outputAll=$ARGV[3];

my %comptrOut=();

open COMPTR, "$comptrOut" or die $!;

while (<COMPTR>){
	chomp;
	$_=~s/[";]//g;
	my @line=split "\t";
	my @trList=split(",", $line[2]);
	$line[1]=~s/^Exact$/sameIntronSet/;
	$line[1]=~s/^Inclusion$/intronSubset/;
	$line[1]=~s/^Extension$/intronSuperset/;
	$line[1]=~s/^Overlap$/overlapNoCommonIntrons/;
	@{$comptrOut{$line[0]}{$line[1]}}=@trList;
}
#print STDERR Dumper \%comptrOut;
close COMPTR;

my %assessedGffHash=gffToHash($assessedGff, 'transcript_id', 0, 'exon');
my %refGffHash=gffToHash($refGff, 'transcript_id', 0, 'exon');
#print STDERR Dumper \%assessedGffHash;
#print STDERR Dumper \%refGffHash;


my %transcript_relationships=();
my %transcript_relationships_reorganized=();
my %transcript_distances=();

foreach my $assessedTid (keys %comptrOut){
	#print STDERR $assessedTid." assessed\n";
  	my $assessedTidStart='';
  	my $assessedTidEnd='';
  	my $assessedTidChr='';
  	my $assessedTidStrand='';
  	if (exists $assessedGffHash{$assessedTid}){
  		my $maxExonEnd=0;
  		my $minExonStart=1000000000000000000000000000000000000000000000000;
  		foreach my $assessedGffRecord (@{$assessedGffHash{$assessedTid}}){ #sort 	exon records by exon start

  			if(${$assessedGffRecord}[3]<$minExonStart){
  				$minExonStart=${$assessedGffRecord}[3]
  			}
  			if(${$assessedGffRecord}[4]>$maxExonEnd){
  				$maxExonEnd=${$assessedGffRecord}[4];
  			}
  			$assessedTidChr=${$assessedGffRecord}[0];

			$assessedTidStrand=${$assessedGffRecord}[6];
  		}
  		$assessedTidStart=$minExonStart;
		$assessedTidEnd=$maxExonEnd;
  		#print STDERR "trStart $minExonStart\ttrEnd $maxExonEnd\n";

	}
	else{
		die "Couldn't find $assessedTid in GFF $assessedGff\n";
	}
  	foreach my $comptrCategory (keys %{$comptrOut{$assessedTid}}){
#  		print STDERR "$assessedTid\t$comptrCategory\n";
  		foreach my $relatedTid (@{$comptrOut{$assessedTid}{$comptrCategory}}){
  			#print STDERR $relatedTid." related\n";
  			if($relatedTid eq '.'){
  				${$transcript_relationships{$assessedTid}{$comptrCategory}}[0]='.';
  			}
  			else{
  				#get transcript's coords from gff
  				my $relatedTidStart='';
 	 			my $relatedTidEnd='';
  				my $relatedTidChr='';
  				my $relatedTidStrand='';
  				if(exists $refGffHash{$relatedTid}){
  					my $maxExonEnd2=0;
  					my $minExonStart2=1000000000000000000000000000000000000000000000000;
 	 				foreach my $relatedGffRecord (@{$refGffHash{$relatedTid}}){
 	 					if(${$relatedGffRecord}[3]<$minExonStart2){
  							$minExonStart2=${$relatedGffRecord}[3]
  						}
  						if(${$relatedGffRecord}[4]>$maxExonEnd2){
  							$maxExonEnd2=${$relatedGffRecord}[4];
  						}
						$relatedTidChr=${$relatedGffRecord}[0];
						$relatedTidStrand=${$relatedGffRecord}[6];

					}
					$relatedTidStart=$minExonStart2;
					$relatedTidEnd=$maxExonEnd2;
  					#print STDERR "trStart $minExonStart2\ttrEnd $maxExonEnd2\n";

					#print STDERR "$assessedTid\t";
					#print STDERR "$assessedTidStart,$assessedTidEnd,$relatedTidStart,$relatedTidEnd,$assessedTidChr,$relatedTidChr,$assessedTidStrand,$relatedTidStrand\n";
					my @overlap=overlap::overlap($assessedTidStart,$assessedTidEnd,$relatedTidStart,$relatedTidEnd,$assessedTidChr,$relatedTidChr,$assessedTidStrand,$relatedTidStrand);
					my $subCategory='';
					if($overlap[0]==1){
						$subCategory='shorter5pEnd.shorter3pEnd';
					}
					elsif($overlap[0]==2){
						$subCategory='longer5pEnd.shorter3pEnd';
					}
					elsif($overlap[0]==3){
						$subCategory='shorter5pEnd.longer3pEnd';
					}
					elsif($overlap[0]==4){
						$subCategory='longer5pEnd.longer3pEnd';
					}
					elsif($overlap[0]==5){
						$subCategory='shorter5pEnd.same3pEnd';
					}
					elsif($overlap[0]==6){
						$subCategory='same5pEnd.shorter3pEnd';
					}
					elsif($overlap[0]==7){
						$subCategory='same5pEnd.same3pEnd';
					}
					elsif($overlap[0]==8){
						$subCategory='longer5pEnd.same3pEnd';
					}
					elsif($overlap[0]==9){
						$subCategory='same5pEnd.longer3pEnd';
					}
					else{
						die "Unknown overlap category: $assessedTid / $relatedTid : $assessedTidStart,$assessedTidEnd,$relatedTidStart,$relatedTidEnd,$assessedTidChr,$relatedTidChr,$assessedTidStrand,$relatedTidStrand -> '$overlap[0]'. Cannot continue.\n";
					}
					push(@{$transcript_relationships{$assessedTid}{"$comptrCategory.$subCategory"}},$relatedTid);
					$transcript_relationships_reorganized{$assessedTid}{$relatedTid}="$comptrCategory.$subCategory";
					$transcript_distances{$assessedTid}{$relatedTid}= abs($overlap[1]) + abs($overlap[2]); # transcript "edit distance"
				}
				else{
					die "Couldn't find $relatedTid in GFF $refGff\n";
				}

			}
		}
  	}
}
foreach my $assessedTid (sort keys %transcript_relationships){
	#print STDERR "$assessedTid ".Dumper \%{$transcript_relationships{$assessedTid}};
	foreach my $comptrSubCategory (keys %{$transcript_relationships{$assessedTid}}){
		if($comptrSubCategory eq 'Monoexonic' || $comptrSubCategory eq 'Intergenic_or_antisense'){
			print "$assessedTid\t$comptrSubCategory\t.\n";
		}
	}

	if ($outputAll ==1){

		# foreach my $comptrSubCategory (keys %{$transcript_relationships{$assessedTid}}){
	 # 		print "$assessedTid\t$comptrSubCategory\t".join(",", @{$transcript_relationships{$assessedTid}{$comptrSubCategory}})."\n";
	 # 	}
	}
	elsif($outputAll==0){ #output only one reference
		foreach my $relatedTid ( sort { $transcript_distances{$assessedTid}{$a} <=> $transcript_distances{$assessedTid}{$b} } keys %{$transcript_distances{$assessedTid}}){
			print "$assessedTid\t$transcript_relationships_reorganized{$assessedTid}{$relatedTid}\t$relatedTid\n";
			last; #to output only one relatedTid per assessedTid
		}
	 }
	 else{
	 	die "Wrong value for 4th argument ($outputAll, 0 or 1). Cannot continue.\n";
	 }
}