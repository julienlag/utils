#!/usr/bin/perl -w
use strict;
use strict 'refs';
use warnings;
use Data::Dumper;
$|=1;


#reads the output of "coverageBed -d" run with a GFF file as input "A" file
#chr1    ENSEMBL gene    134212703       134230065       .       +       .       gene_id "ENSMUSG00000009772"; transcript_id "ENSMUSG00000009772"; exon_number "1"; gene_name "Nuak2"; gene_type "protein_coding"; transcript_name "Nuak2-002"; transcript_type "protein_coding";        13121   0
#chr1    ENSEMBL gene    134212703       134230065       .       +       .       gene_id "ENSMUSG00000009772"; transcript_id "ENSMUSG00000009772"; exon_number "1"; gene_name "Nuak2"; gene_type "protein_coding"; transcript_name "Nuak2-002"; transcript_type "protein_coding";        13122   0

my $totalMappedReadNts=$ARGV[1];

my %record2depth=();
while (<STDIN>){
#	print;
	chomp;
	my @line=split "\t";
	my $depth=pop(@line);
	pop(@line);
	my $gffRecord=join("\t", @line);
#	print $gffRecord."\n";
#	print $depth."\n";
	$record2depth{$gffRecord}+=$depth;
#	print "$record2depth{$gffRecord}\n";
}


foreach my $gffRecord (keys %record2depth){
	my @line=split("\t", $gffRecord);
	my $length=($line[4]-$line[3])+1;
	my $bpkm=$record2depth{$gffRecord}/($length/1000)/($totalMappedReadNts/1000000);
	print $gffRecord." mappedReadNts \"$record2depth{$gffRecord}\"; BPKM \"$bpkm\";\n";
}
