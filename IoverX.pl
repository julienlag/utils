#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use Data::Dumper;
die "need 3 args\n" unless ($#ARGV==2);

open INTER, "$ARGV[0]" or die $!; #intersection of sets
open INDIV, "$ARGV[1]" or die $!; #coverage of each set

my $scoretype=$ARGV[2];

die "Wrong scoretype\n" unless ($scoretype eq 'IoU' || $scoretype eq 'IoX' || $scoretype eq 'IoY');

#if (defined $ARGV[2]){
#	open INCLUSION_SETS, "grep -vP \"^#\" $ARGV[2]|" or die $!;#tab-separated list of sets that are supposedly included in other sets. see e.g. ~/projects/encode/scaling/whole_genome/analysis/intersect/inclusion_sets.tsv
#}
my %indiv;
#my %inclusion_sets;
#if (defined $ARGV[2]){
#	while (<INCLUSION_SETS>){
#		chomp;
#		my @line= split "\t";
#		$inclusion_sets{$line[0]}{$line[1]}=1;
#	}
#}

while (<INDIV>){
	chomp;
	my @line= split "\t";
	$indiv{$line[0]}=$line[1];
}
#print Dumper \%indiv;
while (<INTER>){
	chomp;
	my @line=split "\t";
	my $set1=$line[0]; # that's set Y
	my $set2=$line[1]; # that's set X
#$_=~s/_/\t/g;
#@line=split "\t";
	my $score;
	#my $scoretype='';
	#if(exists $inclusion_sets{$line[0]}{$line[4]}){
	#	$score=$line[8]/$indiv{$set1}; #inclusion of tech1 in tech2
	#	$scoretype='incl';
	#}
	#else{
	if($scoretype eq 'IoU' || $scoretype eq 'IoX'){
		unless($indiv{$set2}==0){
			if($scoretype eq 'IoX'){
				$score=$line[2]/$indiv{$set2}; #Intersection / X
				#$scoretype='I/X';
			}
			else{
				$score=$line[2]/(($indiv{$set1}+$indiv{$set2})-$line[2]); #Intersection / Union

			}
			#$score=sprintf("%.6f",$score);
			print "$set1\t$set2\t$score\t$scoretype\n";
		}
	}
	else{
		unless($indiv{$set1}==0){
			$score=$line[2]/$indiv{$set1}; #Intersection / Y
			#$score=sprintf("%.6f",$score);
			print "$set1\t$set2\t$score\t$scoretype\n";
		}
		
	}
		#}
		
}

