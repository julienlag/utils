#!/usr/bin/perl -w

use strict;
use warnings;
#use Data::Dumper;
use diagnostics;

# filters out unspliced matches if desired (block count < 2 and intronsize<33) and non-best matches for which match / Q size < $minmatch
#arg1: PSL file name
#arg2: for each query seq, output best alignment AND all non-best alignments having (match / query size > arg2). If you want ONLY the best match, set it to '1'
###possible values: any number between 0 and 1.
#arg3: specifies if the hits output should be spliced (i.e. block count>=2 and intronSize>33 nts) or not.
###possible values: 'spliced' or 'unspliced' ("unspliced" means "spliced and unspliced")
#arg4: minimum alignment coverage of the query seq required to be output. the alignment coverage for each hit is calculated as:
###(matches+mismatches+repMatches)/qSize
###possible values: any number between 0 and 1.

#Example: perl filter_psl.pl some_PSL.psl 1 unspliced 0.95

open I, "$ARGV[0]" or die "$ARGV[0]: ".$!;
my $outIntron= $ARGV[0]."_introns.tsv";
open INTRONS, ">$outIntron" or die $!;
my $minmatch=$ARGV[1];
my $spliced=$ARGV[2];
my $mincoverage=$ARGV[3];
unless ($minmatch){
	die "You didn't specify a min ID (between 0 and 1)\n";
}
unless ($mincoverage){
	die "You didn't specify a min coverage (between 0 and 1)\n";
}

unless((defined $spliced) && ($spliced eq 'spliced' || $spliced eq 'unspliced')){
	die "Tell me if you want spliced hits only ('spliced') or spliced+unspliced ('unspliced')\n";

}
my $spliced_suffix_for_outfile;

if($spliced eq 'spliced'){
	$spliced_suffix_for_outfile='spliced_only';
}
else{
	$spliced_suffix_for_outfile='spliced_and_unspliced';
}

my $filtout=$ARGV[0]."filt_min$minmatch"."or_best_".$mincoverage."cov_"."$spliced_suffix_for_outfile".".psl";


open FILTOUT, ">$filtout" or die $!;
my @line;
my @blocksizes;
my @tstarts;
my $intronsize;
my %EST_hits=();

#unless (dbmopen(%EST_hits, 'EST_hits', 0644)){
#	die "cannot open DBM EST_hits\n";
#}

my %pslIndex=();
#unless (dbmopen(%pslIndex, 'pslIndex', 0644)){
#	die "cannot open DBM pslIndex\n";
#}

my $autoIncIndex=0;
while(<I>){
	#print STDERR $autoIncIndex."\n";
	@line=split "\t";
	my $pslline=$_;
	chomp $pslline;
	unless($line[0]=~/^\d+$/){ #skips header
		next;
	}
#	unless ($line[17]>1){ #skips unspliced matches
		#next;
#	}
	#my $qCoverage=($line[0]+$line[1]+$line[2])/$line[10];
	my $qCoverage=($line[12]-$line[11])/$line[10];
	unless ($qCoverage > $mincoverage){ #filter out < $mincoverage hits)
		next;
	}

	$autoIncIndex++;
	$pslIndex{$autoIncIndex}=$pslline;
	#my @est_score=($line[9],$line[0]);
	$EST_hits{$line[9]}{$qCoverage}{$line[0]}{$line[13]}{$line[15]}= $autoIncIndex;
	#print Dumper \%EST_hits;
}

#print STDERR Dumper \%EST_hits; 
foreach my $est (keys %EST_hits){
	my $counthits=0;
	#print STDERR "$est\n";
	foreach my $qCoverage (sort {$b <=>$a} keys %{$EST_hits{$est}}){
		foreach my $hit_score (sort {$b <=>$a} keys %{$EST_hits{$est}{$qCoverage}}){
		#print "$est\t$hit\n";
			foreach my $hit_chr (keys %{$EST_hits{$est}{$qCoverage}{$hit_score}}){
				foreach my $hit_chr_start (keys %{$EST_hits{$est}{$qCoverage}{$hit_score}{$hit_chr}}){
					$counthits++;
					#print STDERR "$est\t$hit\t$counthits\n";
					my $pslline=$pslIndex{$EST_hits{$est}{$qCoverage}{$hit_score}{$hit_chr}{$hit_chr_start}};
					my @line=split "\t", $pslline;
					@blocksizes=split ",", $line[18];
					@tstarts=split ",", $line[20];
					my $longestintron=0;
					if($#blocksizes>0){
						for (my $i=0; $i<$#blocksizes; $i++){
							#if ($line[8] eq '+'){
							$intronsize=$tstarts[$i+1]-($tstarts[$i]+$blocksizes[$i]);
							my $intronend=$tstarts[$i+1];
							my $intronstart=$tstarts[$i]+$blocksizes[$i];
							#if($intronsize>=$minintron){
							if($intronsize>$longestintron){
								$longestintron=$intronsize;
							}
							print INTRONS "$est\t$line[13]\t$intronstart\t$intronend\t$intronsize\n";
						}
					}
					
					#unless($longestintron>33){ #skips hits "mistakenly" spliced by blat
					#$counthits++;
					#next;
					#}
					#print STDERR "COUNTHITS: '$counthits'\n";
					#print STDERR $pslline;
					#$counthits=4;
					if(($spliced eq 'spliced' && $longestintron>33) || $spliced eq 'unspliced'){
						if ($counthits== 1){ # i.e. best hit for EST
							print FILTOUT $pslline."\n";
						}
						
					#	elsif ($line[0]/$line[10]>$minmatch && $qCoverage ){
					#		print FILTOUT $pslline."\n";
					#	}
					}
				}
			}
		}
	}
}
#	my @line=split "\t", ;
#	@blocksizes=split ",", $line[18];
#	@tstarts=split ",", $line[20];
#	my $longestintron=0;
#	for (my $i=0; $i<$#blocksizes; $i++){
#		if ($line[8] eq '+'){
#			$intronsize=$tstarts[$i+1]-$tstarts[$i]+$blocksizes[$i];
#			if($intronsize>=$minintron){
#				if($intronsize>$longestintron){
#					$longestintron=$intronsize;
#				}
#				#print MININTRON "$pslline\t$intronsize\n";
				
				#last;
#			}
#		}
#		elsif($line[8] eq '-'){
#			$intronsize=($tstarts[$i+1]-$blocksizes[$i+1])-$tstarts[$i];
#			if($intronsize>=$minintron){
#				if($intronsize>$longestintron){
#					$longestintron=$intronsize;
#				}
#				#print MININTRON "$pslline\t$intronsize\n";
#				
#				#last;
#			}
#		}
#		else{
#			print STDERR "Line $.: couldn't read strand info:\n$_";
#		}
#		
#	}
#	print MININTRON "$pslline\t$longestintron\n";
#	unless ($line[0]/$line[10]>$minmatch){
#		next;
#	}
	
#	print STDOUT ;
#}
