#!/usr/local/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
my $pslfilename= $ARGV[0];
my $primerlist=$ARGV[1];
open PSL, "$pslfilename" or die $!;


my $mincov=$ARGV[2];
my $minid=$ARGV[3];
my $revcomp=$ARGV[4];
die "\n\n\$revcomp eq 'revcomp' || \$revcomp eq 'norevcomp'\n\n" unless($revcomp eq 'revcomp' || $revcomp eq 'norevcomp');

my $deselected_primers=$pslfilename."_deselected_".$mincov."_".$minid.$revcomp.".list";
my $selected_primers=$pslfilename."_selected_".$mincov."_".$minid.$revcomp.".list";
my $nomatch=$pslfilename."_noperfectmatch.list";
open DESELECTED, ">$deselected_primers" or die $!;
open SELECTED, ">$selected_primers" or die $!;
open NOMATCH, ">$nomatch" or die $!;
my %seen_primer=();
my %perfect_match_found=();

if($revcomp eq 'revcomp'){
	$revcomp=1;
}
else{
	$revcomp=0;
}


while (<PSL>){
	my @line=split "\t";
	my $q=$line[9];
	my $qend=$line[12];
	my $qstart=$line[11];
	my $qsize=$line[10];
	my $matches=$line[0];
	my $mismatches=$line[1];
	my $repmatches=$line[2];
	my $strand=$line[8];
	if($qstart==0 && $qend == $qsize){
		$perfect_match_found{$q}=1;
	}
	if($revcomp==0){
		unless($qend>=$qsize-3){ # 3' end of primer matches perfectly
			next;
		}
	}
	else{
		unless($qstart<=3){ # 3' end of primer matches perfectly
			next;
		}
	}

	#print STDERR "$_\n\tcov: ($line[12]-$line[11])/$line[10]\n\tid: ($line[0]+$line[1]+$line[2])/ ($line[12]-$line[11])\n";
	unless (($qend-$qstart)/$qsize > $mincov){ #filter out <$mincov-coverage hits
#            qend      qstart     qsize
		next;
	}
	unless (($matches+$mismatches+$repmatches)/ ($qend-$qstart) > $minid){ #filter out <$minid-%identity hits
#            match  mismatch   repmatch    qend      qstart
		next;
	}
	if(!exists $seen_primer{$q}){
		$seen_primer{$q}=1;
	}
	else{
		$seen_primer{$q}++;
	}
}

close PSL;
open PRIMERLIST, "$primerlist" or die $!;
while (<PRIMERLIST>){
	$_=~/(\S+)/;
	#print STDERR "$1\t$seen_primer{$1}\n";
	if (!exists ($seen_primer{$1}) || $seen_primer{$1}==1){
		print SELECTED "$1\n";
	}
	else{
		print DESELECTED "$1\n";
	}
	if(!exists ($perfect_match_found{$1})){
		print NOMATCH "$1\n";
	}
	
}

