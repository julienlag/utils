#!/usr/bin/perl -w

use strict;
use warnings;

## given a fasta file, translates in all 6 frames and outputs the longest peptide sequence for each fasta record.

open I, "cat $ARGV[0] | FastaToTbl |" or die $!;

my $pep_out=$ARGV[0]."_CDS.pep";

open PEP, ">$pep_out" or die $!;

my $pep;
while (<I>){
	chomp;
	my @tblRecord=split " ";
	my @pepSeqs=()
	for(my $i=1; $i<=3;$i++){
		my $pepSeqs[$i]=`transeq -frame $i -auto -stdout -osformat2 plain $tblRecord[1]`;
	}
	my @pepSeqLengths=();
	for(my $i=0; $i<=$#pepSeqs; $i++){

	my @pep = split(//, $pepSeqs[$i]);
	
	
	my@pep2 = split(//, $pep2);
	my@pep3 = split(//, $pep3);
	my $stop_idx1=$#pep1;
	my $stop_idx2=$#pep2;
		my $stop_idx3=$#pep3;
		
		for (my $i=0;$i<=$#pep1 ;$i++){
			if($pep1[$i] eq '*'){
				$stop_idx1=$i;
				last;
			}
		}
		for (my $i=0;$i<=$#pep2 ;$i++){
			if($pep2[$i] eq '*'){
				$stop_idx2=$i;
				last;
			}
		}
		for (my $i=0;$i<=$#pep3 ;$i++){
			if($pep3[$i] eq '*'){
				$stop_idx3=$i;
				last;
			}
		}
		if ($stop_idx1>=$stop_idx2 && $stop_idx1>=$stop_idx3){
			$pep=$pep1;
$frame_used=1;

		}
		elsif($stop_idx2>=$stop_idx1 && $stop_idx2>=$stop_idx3){
			$pep=$pep2;
$frame_used=2;
		}
		elsif($stop_idx3>=$stop_idx1 && $stop_idx3>=$stop_idx2){
			$pep=$pep3;
$frame_used=3;
		}
		else{
			print STDERR "ARRRRRRRRRRRRRRRRRRGH!!!!\n";
		}
	}
	else{
		$pep=`transeq -frame $first_frame -auto -stdout -osformat2 plain $nuc_out:$transcript`;
$frame_used=$first_frame;
	}
	$pep=~s/\s//g;
$fasta_remark.=" [strand= $transcripts_strand{$transcript}] [ann_first_frame= $first_frame] [frame_used= $frame_used]";
	print PEP ">$transcript$fasta_remark\n";
	
	for(my $k=0;$k<=length($pep);$k=$k+60){
		print PEP substr($pep,$k,60)."\n";
	}


}
close I; close NUC; close PEP;
#my $pep=`transeq -auto -stdout -osformat2 fasta $nuc_out`;
#print PEP $pep;


#foreach my $transcript (@transcs){
#	my @list=$db->get_feature_by_name('transcript_id' => $vega2gbrowse{$transcript});
#	unless($#list==0){
#		print STDERR "Couldn't find $vega2gbrowse{$transcript} in database\n";
#	}
#	foreach my $feat (@list){
#		my @subfeats= $feat->sub_SeqFeature('CDS');
#		foreach my $subfeat(@subfeats){
#			my $rel_subfeat=$feat->new_from_parent;
#			my $str = $rel_subfeat->gff_string;
#			print "$str\n";
#		}
#	}
#}
