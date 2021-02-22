#!/usr/bin/perl

use lib "/users/rg/jlagarde/julien_utils/";
use strict;
use warnings;
use Data::Dumper;



## based on a BLAST alignment of transcripts vs. transcripts. hard-masks regions of nucleotide similarity in "Query" transcripts


## input:
#$ARGV[0]= blast alignment
#$ARGV[1]=GTF file containing gene_id's and transcript_id's (this is to map transcript IDs to gene IDs, and mask sequences similar to sequences in *other loci only*)
#$ARGV[2]=sequences to mask, in TBL format

open GTF, "$ARGV[1]" or die $!;

my %transcript_id_2_gene_id=();

while (<GTF>){
	chomp;
	my $both_attr_found=0;
	my $t_id='';
	my $g_id='';

	if($_=~/transcript_id "(\S+)";/){
		$t_id=$1;
		$both_attr_found++;
	}
	if($_=~/gene_id "(\S+)";/){
		$g_id=$1;
		$both_attr_found++;
	}
	if($both_attr_found==2){
		$transcript_id_2_gene_id{$t_id}=$g_id;
	}
	else{
		print STDERR "Could not find gene_id or transcript_id at: \n$_\n";
	}
}
close GTF;
#print Dumper \%transcript_id_2_gene_id;

open TBL, "$ARGV[2]" or die $!;

my %transcript_seq=();

while (<TBL>){
	$_=~/(\S+) (\S+)$/;
	@{$transcript_seq{$1}}=split('',$2);
}

#print Dumper \%transcript_seq;

open BLAST, "$ARGV[0]" or die $!;
my $gffout=$ARGV[0].".gff";
open GFF, ">$gffout" or die $!;

while (<BLAST>){
	next if ($_=~/^#/);
	my @line=split "\t";
	my $query=$line[0];
	my $subject=$line[1];
	my $queryStart=$line[6]-1;
	my $queryEnd=$line[7]-1;

	my $strand='';
	if($line[9]<=$line[8]){
		$strand='-';
	}
	else{
		$strand='+'
	}
	unless($transcript_id_2_gene_id{$query} eq $transcript_id_2_gene_id{$subject}){
		for(my $i=$queryStart;$i<=$queryEnd;$i++){
			${$transcript_seq{$query}}[$i]='N';
		}


		my $queryStartGff=$queryStart+1;
		my $queryEndGff=$queryEnd+1;
		
		print GFF "$query\tBLAST\tHSP\t$queryStartGff\t$queryEndGff\t.\t$strand\t.\t$subject; perCentIdentity \"$line[2]\";\n";





	}
	else{
	#	print STDERR "$query $subject same locus $transcript_id_2_gene_id{$query} $transcript_id_2_gene_id{$subject}\n";
	}
}

#print Dumper \%transcript_seq;

foreach my $tr (keys %transcript_seq){
	print "$tr ".join('', @{$transcript_seq{$tr}})."\n";
}
