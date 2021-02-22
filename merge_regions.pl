#!/usr/bin/perl
use strict; 
use warnings;

#input file must be GZIPPED/PLAIN BED file!!
#does NOT take strand into account
#example: perl ~/julien_utils/merge_regions.pl $file 15 nosort


my $sort_or_not=$ARGV[2];
# $sort_or_not must be string "sort" (input file is not sorted) or "nosort" (input file is already sorted)
#print $sort_or_not;
die "Sort or not?" unless ($sort_or_not && ($sort_or_not eq 'sort' || $sort_or_not eq 'nosort'));

if($ARGV[0]=~/\.gz$/){
	if($sort_or_not eq 'sort'){
		open F, "gzip -cd $ARGV[0]| sort -k1,1 -k2,2n -k3,3n|" or die $!;
	}
	else{
		open F, "gzip -cd $ARGV[0]|" or die $!;
	} 
}
else{
	if($sort_or_not eq 'sort'){
		open F, "sort -k1,1 -k2,2n -k3,3n $ARGV[0]|" or die $!; 
	}
	else{
		open F, "$ARGV[0]" or die $!; 

	}
}

my $previousend=0; 
my $currentstart=0; 
my $currentend=0; 
#my $newblock=1; 
my $blockstart=-$ARGV[1]-1;
my $previouschr='previouschr';
my $currentchr='currentchr';
my $emptyfile=1;
while(<F>){
	$emptyfile=0;
	#print; 
	#print "   prevend= $previousend , currstart= $currentstart , currentend= $currentend , blockstart= $blockstart\n"; 
	chomp; 
	my @line = split "\t";
	$currentchr=$line[0];
	#print STDERR "$.\n";
	die "Unrecognized format. Should be BED. (line $. $_\nchr $currentchr)\n" unless ($currentchr=~/^chr/);
	$currentstart=$line[1]-$ARGV[1]; 
	die "Unrecognized format. Should be BED. (line $. $_\nstart $currentstart)\n" unless ($currentstart=~/^-*\d+$/);
	$currentend=$line[2]+$ARGV[1];
	die "Unrecognized format. Should be BED. (line $. $_\nend $currentend)\n" unless ($currentend=~/^-*\d+$/);
	
	if($blockstart<-$ARGV[1]){ # we're at the first feature
		$blockstart=$currentstart;
		$previousend=$currentend;
		$previouschr=$currentchr;
		#$newblock=0;
	}
	else{
		if($currentchr eq $previouschr && $currentstart < $previousend){# overlap with previous feature
			if($currentend>$previousend){ # current feature goes further than previous
				$previousend=$currentend;
			}
		}

		else{ #no overlap with previous feature, let's print the previous block
			#$currentend=$currentend-15;
			
			$previousend=$previousend-$ARGV[1];
			$blockstart=$blockstart+$ARGV[1];
			print $previouschr."\t".$blockstart."\t".$previousend."\n";
			#$newblock=1;
			$blockstart=$currentstart;
			$previousend=$currentend;
			$previouschr=$currentchr;
		}
	}
}
unless($emptyfile){
	$previousend=$previousend-$ARGV[1];
	$blockstart=$blockstart+$ARGV[1];
	print $currentchr."\t".$blockstart."\t".$previousend."\n"; #print last block
}
