#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
$|=1;



# collapses identical exons (same start/end/strand) belonging to different transcripts into one single entry:

# chr7    ENSEMBL exon    50607992        50608039        .       +       .       gene_ids "ENSMUSG00000039013"; transcript_ids "ENSMUST00000122423,ENSMUST00000085470,ENSMUST00000121494,ENSMUST00000012798,ENSMUST00000145867"; exon_id "chr7_50607992_50608039_+";  RPKM1 "0.023645"; RPKM2 "0.073019"; iIDR "0.134";

#also collapses gene entries this way:
#chr4    ENSEMBL gene    137990586       137998180       .       +       .       gene_id "ENSMUSG00000041241"; transcript_ids "ENSMUST00000105814,ENSMUST00000105813,ENSMUST00000044058,ENSMUST00000105815";  reads "4290.000099"; RPKM1 "6.709479"; RPKM2 "5.334376"; iIDR "0.000";


my %gene2transcripts=();
my %geneRecord=();
my %exon2transcripts=();
my %exon2genes=();
my %exonRecord=();


while (<STDIN>){
	chomp;
	my @line=split "\t";
	my $line=$_;
	
	if($line[2] eq 'gene'){
		if($line=~/gene_id \"(\S+)\"/){
			my $geneid=$1;
			$geneRecord{$geneid}=$line;
		}
		else{
			next "Skipped line $. (Gene records without gene_id attribute):\n$_\n";
			
		}
	}
	elsif($line[2] eq 'exon'){
		my $exonid=$line[0]."_".$line[3]."_".$line[4]."_".$line[6];
		$exonRecord{$exonid}=$line;
		if($line=~/transcript_id \"(\S+)\"/){
			my $transcriptid=$1;
			if($line=~/gene_id \"(\S+)\"/){
				my $geneid=$1;
				${$gene2transcripts{$geneid}{$transcriptid}}=1;
				${$exon2transcripts{$exonid}{$transcriptid}}=1;
				${$exon2genes{$exonid}{$geneid}}=1;
			}
			else{
				next "Skipped line $. (exon record without gene_id attribute):\n$_\n";
			}
		}
		else{
			next "Skipped line $. (exon record without transcript_id attribute):\n$_\n";
		}
	}
}


foreach my $geneid (keys %gene2transcripts){
	my @transcriptsList=();
	foreach my $transcriptid (keys %{$gene2transcripts{$geneid}}){
		push(@transcriptsList,$transcriptid);
	}
	my @gffline=split("\t", $geneRecord{$geneid});
	print "$gffline[0]\t$gffline[1]\tgene\t$gffline[3]\t$gffline[4]\t.\t$gffline[6]\t$gffline[7]\tgene_id \"$geneid\"; transcript_ids \"".join(",",@transcriptsList)."\";\n";
}


foreach my $exonid (keys %exon2transcripts){
	my @transcriptsList=();
	my @genesList=();
	foreach my $geneid (keys %{$exon2genes{$exonid}}){
		push(@genesList,$geneid);
	}
	foreach my $transcriptid (keys %{$exon2transcripts{$exonid}}){
		push(@transcriptsList,$transcriptid);
	}
	my @gffline=split("\t", $exonRecord{$exonid});
	print "$gffline[0]\t$gffline[1]\texon\t$gffline[3]\t$gffline[4]\t.\t$gffline[6]\t$gffline[7]\tgene_ids \"".join(",",@genesList)."\"; transcript_ids \"".join(",",@transcriptsList)."\"; exon_id \"$exonid\";\n";
}
