#!/usr/local/bin/perl -w
use strict;
use warnings;
use diagnostics;
#use Bio::DB::GFF;
#use Bio::SeqIO;
use Data::Dumper;
#use overlap;

#input sorted gff3 file!!!



my %transcripts_exon_starts=();
my %transcripts_exon_ends=();
my %transcripts_CDS_start=();
my %transcripts_CDS_end=();
my %transcript_chr=();
my %transcript_cat=();
my %transcript_str=();
while(<>){
	chomp;
	my @line=split "\t";
	if($line[2] eq 'exon'){
		push(@{$transcripts_exon_starts{$line[8]}}, $line[3]);
		push(@{$transcripts_exon_ends{$line[8]}}, $line[4]);
	}
	elsif($line[2] eq 'CDS'){
		$transcripts_CDS_start{$line[8]}=$line[3];
		$transcripts_CDS_end{$line[8]}= $line[4];
		$transcript_chr{$line[8]}=$line[0];
		$transcript_cat{$line[8]}=$line[1];
		$transcript_str{$line[8]}=$line[6];
	}
}

# print Dumper \%transcripts_CDS_start;
# print Dumper \%transcripts_CDS_end;
# print Dumper \%transcripts_exon_starts;
# print Dumper \%transcripts_exon_ends;


foreach my $transcript (keys %transcripts_exon_starts){
	my $CDSstart=$transcripts_CDS_start{$transcript};
	my $CDSend=$transcripts_CDS_end{$transcript};
	for(my $i=0;$i<=$#{$transcripts_exon_starts{$transcript}};$i++){
		my $exonstart=${$transcripts_exon_starts{$transcript}}[$i];
		my $exonend=${$transcripts_exon_ends{$transcript}}[$i];
		if($CDSstart<$exonend && $CDSstart>=$exonstart){
		   if ($CDSend>=$exonend){
			   print "$transcript_chr{$transcript}\t$transcript_cat{$transcript}\tCDS\t$CDSstart\t$exonend\t.\t$transcript_str{$transcript}\t.\t$transcript\n";
			   print "$transcript_chr{$transcript}\t$transcript_cat{$transcript}\texon\t$exonstart\t$exonend\t.\t$transcript_str{$transcript}\t.\t$transcript\n";
		   }
		   else{
			   print "$transcript_chr{$transcript}\t$transcript_cat{$transcript}\tCDS\t$exonstart\t$CDSend\t.\t$transcript_str{$transcript}\t.\t$transcript\n";
			   print "$transcript_chr{$transcript}\t$transcript_cat{$transcript}\texon\t$exonstart\t$exonend\t.\t$transcript_str{$transcript}\t.\t$transcript\n";

		   }
		}
		elsif($CDSend<=$exonend && $CDSend>$exonstart){
			print "$transcript_chr{$transcript}\t$transcript_cat{$transcript}\tCDS\t$exonstart\t$CDSend\t.\t$transcript_str{$transcript}\t.\t$transcript\n";
			print "$transcript_chr{$transcript}\t$transcript_cat{$transcript}\texon\t$exonstart\t$exonend\t.\t$transcript_str{$transcript}\t.\t$transcript\n";
		}
		elsif($CDSstart<$exonstart && $CDSend>$exonend){
			print "$transcript_chr{$transcript}\t$transcript_cat{$transcript}\tCDS\t$exonstart\t$exonend\t.\t$transcript_str{$transcript}\t.\t$transcript\n";
			print "$transcript_chr{$transcript}\t$transcript_cat{$transcript}\texon\t$exonstart\t$exonend\t.\t$transcript_str{$transcript}\t.\t$transcript\n";
		}
		else{
			print "$transcript_chr{$transcript}\t$transcript_cat{$transcript}\texon\t$exonstart\t$exonend\t.\t$transcript_str{$transcript}\t.\t$transcript\n";
		}
	}
	
}
