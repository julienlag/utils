#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
#use Bio::DB::GFF;
#use Bio::SeqIO;
#use Data::Dumper;

open I, "$ARGV[0]" or die $!;

#my %exonstart;
#my %exonend;
#my %exonstrand;
#my %exonchr;
my $nuc_out=$ARGV[0]."_exon_seqs.fa";

open NUC, ">$nuc_out" or die $!;

while (<I>){
	if ($_=~/^(\S+)\t(\S+)\tCDS\t(\d+)\t(\d+)\t\S+\t(\S+)\t(\S+)\t.*exon_id "(\S+)?";.*\n/){
		my $chr=$1;
		my $start=$3;
		my $end=$4;
		my $strand=$5;
		my $exon_id=$7;
#		$exonstart{$exon_id}=$start;
#		$exonend{$exon_id}=$end;
#		$exonstrand{$exon_id}=$strand;
#		$exonchr{$exon_id}=$chr;
		my $seq='';
		my $chr_file=$chr.".fa";
		print STDERR "$exon_id\n";
		
		if($strand eq '+' || $strand eq '.'){
			$seq= `chr_subseq /seq/genomes/H.sapiens/golden_path_200603/chromFa/$chr_file $start $end | extractseq -auto -filter -osformat2 fasta |descseq -auto -filter -name "$exon_id"`;
		}
		elsif($strand eq '-'){
			$seq=`chr_subseq /seq/genomes/H.sapiens/golden_path_200603/chromFa/$chr_file $start $end | revseq -auto -filter -osformat2 fasta | descseq -auto -filter -name "$exon_id"`;
		}
		else{
			print STDERR "Couldn't find strand info for exon $exon_id\n";
		}
		print NUC $seq;
	}
}
