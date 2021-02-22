#!/usr/local/bin/perl -w

use strict;
use warnings;
use Data::Dumper;
use diagnostics;
$|=1;
open PSLHITS, "$ARGV[1]", or die $!;
open GFFPRIMERS, "$ARGV[0]", or die $!;

my %primers=();
my $inc=0;
while (<GFFPRIMERS>){
	$inc++;
	chomp;
	my @line=split "\t";
	my $primerid=$line[8]."_$inc";
	push (@{$primers{$primerid}{$line[0]}}, $line[3], $line[4]);

}

#foreach my $primer (keys %primers){
#	foreach my $chr (keys %{$primers{$primer}}){
#		#@{$primers{$primer}{$chr}}= sort ({$a <=> $b} @{$primers{$primer}{$chr}});
#		my $first_start=${$primers{$primer}{$chr}}[0];
#		my $last_stop=${$primers{$primer}{$chr}}[$#{$primers{$primer}{$chr}}];
#		@{$primers{$primer}{$chr}}=($first_start, $last_stop);
#	}
#}

#print Dumper %primers;
#my $autoIncIndex=0;
my %seq_hits=();
my %pslIndex=();
my %hit_intersectwithtarget=();
my %seq_besthit=();

while (<PSLHITS>){
	my %primer_hit_match=();
	chomp;
	my $pslline=$_;
	my @line=split "\t";
	if ($line[12]-$line[11]<100){
		next;
	}
	my $seqid=$line[9];
	$seqid=~/^(chr\S+_\d+_\d+_\S+)_\d+_\S+$/;
	my $targetid=$1;
	#print STDERR $targetid."\n";
	my $hitchr=$line[13];
	#my $hitstart=$line[15];
	#my $hitstop=$line[16];
	my @blocksizes=split (",",$line[18]);
	my @tstarts=split (",", $line[20]);
	#$autoIncIndex++;
	#$pslIndex{$autoIncIndex}=$pslline;
	#$seq_hits{$line[9]}{$line[13]}{$line[15]}{$line[16]}= $autoIncIndex;
	
#	if (exists $primers{$targetid}{$hitchr}){
		#print STDERR "\t$targetid\t$hitchr\n";
	my @firstandlastblock=($tstarts[0],$tstarts[0]+$blocksizes[0], $tstarts[$#tstarts], $tstarts[$#tstarts]+$blocksizes[$#blocksizes]);
	#my @lastblock=($tstarts[$#tstarts], $tstarts[$#tstarts]+$blocksizes[$#blocksizes]);
	for(my $i=0;$i<$#firstandlastblock;$i=$i+2){
		my $hitstart=$firstandlastblock[$i];
		my $hitstop=$firstandlastblock[$i+1];
		my $j=$i+1;
		foreach my $primer (keys %primers){
			my $primerstring='';
			$primer=~/^(\S+)_\d+$/;
			$primerstring=$1;
			foreach my $chr_primer (keys %{$primers{$primer}}){
				next if (exists $primer_hit_match{$primer}{$seqid}{$hitstart}{$hitstop});
				if ($chr_primer eq $hitchr){
					my $starttarget=${$primers{$primer}{$hitchr}}[0];
					my $stoptarget=${$primers{$primer}{$hitchr}}[1];
					my $lengthtarget=$stoptarget-$starttarget;
					my $lengthproduct=$hitstop-$hitstart;
					my @starts=($starttarget,$hitstart);
					my @stops=($hitstop,$stoptarget);
					@starts= sort {$a <=> $b} @starts;
					@stops= sort {$a <=> $b} @stops;
					my $intersection=0;
					if(($starttarget<=$hitstop && $starttarget>=$hitstart) || ($stoptarget<=$hitstop && $stoptarget>=$hitstart) || ($hitstart>=$starttarget && $hitstop<=$stoptarget)){ #check overlap
						$intersection=$stops[0]-$starts[$#starts];
						print STDERR "$primer\t$primerstring\t$starttarget\t$stoptarget\n";
						#if($intersection>0){
						#if(exists $seq_besthit{})
						#my $coverageoftarget=sprintf("%.3f",$lengthproduct/$lengthtarget);
						print STDOUT "$pslline\t$primerstring\t$starttarget->$stoptarget\t$lengthtarget\t$intersection\t$j\n";
						$primer_hit_match{$primer}{$seqid}{$hitstart}{$hitstop}=1;
						#}
					}
				}
			}
			#print STDOUT "$pslline\t$primer\t$intersection\n";
			
		}
	
	}
	
}
