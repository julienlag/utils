#!/usr/bin/perl

use lib "/users/rg/jlagarde/julien_utils/";
use strict; 
use warnings;
use overlap;

$|=1;
#input files must be GZIPPED/PLAIN BED files!!
#does NOT take strand into account
#there should not be any overlapping features within the two files, taken separately
#intervals in file#2 (e.g. genic regions) will be subtracted from intervals in file#1 (e.g. whole genome). file#1-file#2=intergenic portion of the genome.
#i.e., the script will output regions in file#1 not overlapped by any region in file #2

#example: perl ~/julien_utils/merge_regions.pl $file1 $file2  nosort

my $file1=$ARGV[0];
my $file2=$ARGV[1];
my $sort_or_not=$ARGV[2];
# $sort_or_not must be string "sort" (input fileS ARE not sorted) or "nosort" (input fileS ARE already sorted)

die "Sort or not?" unless ($sort_or_not && ($sort_or_not eq 'sort' || $sort_or_not eq 'nosort'));

if($file1=~/\.gz$/){
	if($sort_or_not eq 'sort'){
		open F1, "gzip -cd $file1| sort -k1,1 -k2,2n -k3,3n|" or die $!;
	}
	else{
		open F1, "gzip -cd $file1|" or die $!;
	} 
}
else{
	if($sort_or_not eq 'sort'){
		open F1, "sort -k1,1 -k2,2n -k3,3n $file1|" or die $!; 
	}
	else{
		open F1, "$file1" or die $!; 

	}
}

if($file2=~/\.gz$/){
	if($sort_or_not eq 'sort'){
		open F2, "gzip -cd $file2| sort -k1,1 -k2,2n -k3,3n|" or die $!;
	}
	else{
		open F2, "gzip -cd $file2|" or die $!;
	} 
}
else{
	if($sort_or_not eq 'sort'){
		open F2, "sort -k1,1 -k2,2n -k3,3n $file2|" or die $!; 
	}
	else{
		open F2, "$file2" or die $!; 

	}
}

my @chr1;
my @starts1;
my @ends1;
my @chr2;
my @starts2;
my @ends2;

while(<F1>){
	chomp;
	my @line=split "\t";
	push(@chr1, $line[0]);
	push(@starts1, $line[1]);
	push(@ends1, $line[2]);
}
close F1;
while(<F2>){
	chomp;
	my @line=split "\t";
	push(@chr2, $line[0]);
	push(@starts2, $line[1]);
	push(@ends2, $line[2]);
}	
close F2;

my $bookmark=0;
#my $blockChr=$chr1[0];
#my $blockStart=$starts1[0];
#my $blockEnd=$ends1[0];
for (my $i=0;$i<=$#chr1;$i++){
	#initialize newblocks arrays
	my @newblocksChr=();
	push (@newblocksChr,$chr1[$i]);
	my @newblocksStarts=();
	push (@newblocksStarts,$starts1[$i]);
	my @newblocksEnds=();
	push (@newblocksEnds,$ends1[$i]);
	#my $count_overlapping_blocks=0;
	#print "file1: $chr1[$i]\t$starts1[$i]\t$ends1[$i]\n";
	my $same_chromosome_scanned='null';
	#print STDERR join(",",@newblocksChr)."\n".join(",",@newblocksStarts)."\n".join(",",@newblocksEnds)."\n";
	for (my $j=$bookmark;$j<=$#chr2;$j++){
		#print "file2 (j=$j): $chr2[$j]\t$starts2[$j]\t$ends2[$j]\n";
		if($chr1[$i] eq $chr2[$j]){
			$same_chromosome_scanned=$chr1[$i];
		}
		elsif($same_chromosome_scanned ne 'null'){#chromosome of current feat of file 1 has already been scanned
			#print "same_chromosome_scanned $same_chromosome_scanned\n";
			last;
		}
		my $overlap=overlap::overlap($starts1[$i]+1,$ends1[$i],$starts2[$j]+1,$ends2[$j],$chr1[$i],$chr2[$j],'+','+');
		#print STDERR "file2:\t$chr2[$j]\t$starts2[$j]\t$ends2[$j]\noverlap=$overlap\n";
		#print "\t$overlap\n";
		if($overlap==0 || $overlap==-1){
			
			next;
		}
		elsif($overlap==-2){ #current feat of file2 is already downstream of current feat of file1. since the files are sorted this means nothing can overlap feat1 anymore
			last;
		}
		else{
			if($j>0){
				$bookmark=$j-1;                            ### ? check the -1, and check it's applicable to all $overlap>0
			}
			else{
				$bookmark=$j;
			}
#$count_overlapping_blocks++; #incremented each time one feat from file2 is overlapping current feat of file1
			if($overlap==1){ #block of file1 is entirely covered by one feature of file2
				#then completely subtract this feat on file1
				@newblocksChr=();
				@newblocksStarts=();
				@newblocksEnds=();
			#	print STDERR join(",",@newblocksChr)."\n".join(",",@newblocksStarts)."\n".join(",",@newblocksEnds)."\n";

				last;
			}
			elsif($overlap==2){ #feature in file2 overlaps feat on file1 and extends it on the right
				#        $newblocksChr[$count_overlapping_blocks-1]=$chr1[$i];
				#$newblocksChr[$#newblocksChr]=$chr1[$i];
				#$newblocksStarts[$count_overlapping_blocks-1];
				#        $newblocksEnds[$count_overlapping_blocks-1]=$starts2[$j];
				$newblocksEnds[$#newblocksEnds]=$starts2[$j];
				#print STDERR join(",",@newblocksChr)."\n".join(",",@newblocksStarts)."\n".join(",",@newblocksEnds)."\n";

				last;
			}
			elsif($overlap==3){ #feature in file2 overlaps feat on file1 and extends it on the left
				#print "$chr1[$i]\t$starts1[$i]\t$starts2[$j]\n";
				#        $newblocksChr[$count_overlapping_blocks-1]=$chr1[$i];
				#$newblocksChr[$#newblocksChr]=$chr1[$i];
				#        $newblocksStarts[$count_overlapping_blocks-1]=$ends2[$j];
				$newblocksStarts[$#newblocksStarts]=$ends2[$j];
				#print STDERR join(",",@newblocksChr)."\n".join(",",@newblocksStarts)."\n".join(",",@newblocksEnds)."\n";

			}
			elsif($overlap==4){ #feature in file2 overlaps feat on file1 and is completely included in it
				# $newblocksChr[$count_overlapping_blocks-1]=$chr1[$i];
# 				$newblocksChr[$count_overlapping_blocks]=$chr1[$i];
# 				$newblocksEnds[$count_overlapping_blocks-1]=$starts2[$j];
# 				$newblocksStarts[$count_overlapping_blocks]=$ends2[$j];
				$newblocksChr[$#newblocksChr+1]=$chr1[$i];
				#$newblocksChr[$count_overlapping_blocks]=$chr1[$i];
				#$newblocksEnds[$#newblocksEnds]=$starts2[$j];
				$newblocksStarts[$#newblocksStarts+1]=$ends2[$j];
				$newblocksEnds[$#newblocksEnds+1]=$newblocksEnds[$#newblocksEnds];
				$newblocksEnds[$#newblocksEnds-1]=$starts2[$j];
				#print STDERR join(",",@newblocksChr)."\n".join(",",@newblocksStarts)."\n".join(",",@newblocksEnds)."\n";

			}
			
			
		}
	}
	my $count_overlapping_blocks=$#newblocksStarts+1;
	#print STDERR "\noverlapping blocks $count_overlapping_blocks\n" ;
	#print STDERR @newblocksChr."\n".@newblocksStarts."\n".@newblocksEnds."\n";
	#print STDERR join(",",@newblocksChr)."\n".join(",",@newblocksStarts)."\n".join(",",@newblocksEnds)."\n";
	
	for (my $k=0;$k<=$#newblocksChr;$k++){
		unless($newblocksStarts[$k]==$newblocksEnds[$k]){
			print STDOUT "$newblocksChr[$k]\t$newblocksStarts[$k]\t$newblocksEnds[$k]\n" ;
		}
	}
}
