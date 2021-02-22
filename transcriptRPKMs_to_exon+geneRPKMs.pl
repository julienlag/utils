#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
$|=1;

my $annotFile=$ARGV[0]; # contains the annotation in gtf format. Contains exon+gene records (3rd field) with trasncript_id and gene_id grouping info (in 9th field)
my $quantFile=$ARGV[1]; # gtf quantification file (obtained from Flux capacitor). Must contain transcript records, quantified ("RPKM" attribute) based on $annotFile and a mapping file.
$quantFile=~/(\S+)\.gtf$/;
my $basename=$1;
my $geneQuantFile=$basename.".gene.gtf";
my $exonQuantFile=$basename.".exon.gtf";
open F, "$annotFile" or die $!;

print STDERR "Scanning annotation file $annotFile\n";
my %gene2transcripts=();
my %geneRecord=();
my %exon2transcripts=();
my %exon2genes=();
my %exonRecord=();

my $foundGeneInAnnotFile=0;
my $foundExonInAnnotFile=0;
while (<F>){
	next if ($_=~/^#/);
	chomp;
	my @line=split "\t";
	#my @attrs=split (" ", $line[8]);
	my $line=$_;
	
	if($line[2] eq 'gene'){
		$foundGeneInAnnotFile=1;
		if($line=~/gene_id \"(\S+)\"/){
			my $geneid=$1;
			$geneRecord{$geneid}=$line;
		}
		else{
			warn "Skipped line $. (Gene records without gene_id attribute):\n$_\n";
			next; 
			
		}
	}
	elsif($line[2] eq 'exon'){
		$foundExonInAnnotFile=1;
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
				warn "Skipped line $. (exon record without gene_id attribute):\n$_\n";
				next ;
			}
		}
		else{
			warn "Skipped line $. (exon record without transcript_id attribute):\n$_\n";
			next;
		}
	}
}
close F;
if($foundGeneInAnnotFile ==0){
	die "\n\n#######                  ERROR                   #######\n\nCouldn't find any 'gene' records (i.e. 'gene' in 3rd field of gff') in annotFile $annotFile. Cannot continue.\n\n#######\n\n\n";
}
if($foundExonInAnnotFile ==0){
	die "\n\n#######                  ERROR                   #######\n\nCouldn't find any 'exon' records (i.e. 'exon' in 3rd field of gff') in annotFile $annotFile. Cannot continue.\n\n#######\n\n\n";
}#print Dumper \%exon2genes;


print STDERR "Done\n";
close F;
print STDERR "Scanning gtf quantification file $quantFile\n";
open F, "$quantFile" or die $!;

my %transcriptReads=();
my %transcriptRpkm=();
while (<F>){
                next if ($_=~/^#/);
	chomp;
	my @line=split "\t";
	my $line=$_;
	if($line[2] eq 'transcript'){
		if($line=~/transcript_id \"(\S+)\"/){
			my $transcriptid=$1;
			if($line=~/same_as \"(\S+)\"/){ #if same transcript is present several times we wat to count it only once for gene and exon RPKM calculation). We assume the list is ALWAYS in the same order for all its members. We will only process the first item of the list.
			  my @same_as=split(",", $1);
			  unless($transcriptid eq $same_as[0]){
			      warn "WARNING: $transcriptid duplicate of $same_as[0]. Ignored (i.e. expression measures considered zero for the purpose of gene/exon RPKM calculation).\n";
			      #next;
			      $transcriptRpkm{$transcriptid}=0;
			      $transcriptReads{$transcriptid}=0;
				next;
			}
			 }
			  if($line=~/RPKM (\S+);*/){
				my $measure=$1;
				$measure=~s/("|'|;)//g;
			    $transcriptRpkm{$transcriptid}=$measure;
			   }
			  else{
			    warn "Skipped line $. (transcript record without RPKM attribute):\n$_\n";
			    next;
			   }
			  if($line=~/reads (\S+);*/){
			    my $measure=$1;
				$measure=~s/("|'|;)//g;
$transcriptReads{$transcriptid}=$measure;
			  }
		}
		else{
		  warn "Skipped line $. (transcript record without transcript_id attribute):\n$_\n";
		  next;
		}
	}
}
#print Dumper \%transcriptRpkm;
print STDERR "Done\n";
close F;
#compute geneRPKMs
print STDERR "calculating gene RPKMs\n";
#my %geneRpkm=();
#my %geneReads=();
open O, ">$geneQuantFile" or die $!;
foreach my $geneid (keys %gene2transcripts){
	my $geneRpkm=0;
	my $geneReads=0;
	my $RpkmFound=0;
	my $ReadsFound=0;
	my @transcriptsList=();
	foreach my $transcriptid (keys %{$gene2transcripts{$geneid}}){
		if(exists ($transcriptRpkm{$transcriptid})){
			push(@transcriptsList,$transcriptid);
			$geneRpkm+=$transcriptRpkm{$transcriptid};
			$RpkmFound=1;
		}
		if(exists ($transcriptReads{$transcriptid})){
			$geneReads+=$transcriptReads{$transcriptid};
			$ReadsFound=1;
		}
	}
	if($RpkmFound==0){
		warn "No quantified transcript found for gene $geneid. Skipped.\n";
		next;
	}
	if($ReadsFound==0){
		$geneReads="N/A";
	}
	my @gffline=split("\t", $geneRecord{$geneid});
	print O "$gffline[0]\t$gffline[1]\tgene\t$gffline[3]\t$gffline[4]\t.\t$gffline[6]\t$gffline[7]\tgene_id \"$geneid\"; transcript_ids \"".join(",",@transcriptsList)."\"; RPKM \"$geneRpkm\"; reads \"$geneReads\";\n"
}
close O;
print STDERR "Done\n";

print STDERR "calculating exon RPKMs\n";
#my %geneRpkm=();
#my %geneReads=();
open O, ">$exonQuantFile" or die $!;
foreach my $exonid (keys %exon2transcripts){
	my $exonRpkm=0;
	my $RpkmFound=0;
	#my $ReadsFound=0;
	my @transcriptsList=();
	my @genesList=();
	foreach my $geneid (keys %{$exon2genes{$exonid}}){
		push(@genesList,$geneid);
	}
	foreach my $transcriptid (keys %{$exon2transcripts{$exonid}}){
		if(exists ($transcriptRpkm{$transcriptid})){
			push(@transcriptsList,$transcriptid);
			$exonRpkm+=$transcriptRpkm{$transcriptid};
			$RpkmFound=1;
		}
	}
	if($RpkmFound==0){
		warn "No quantified transcript found for exon $exonid. Skipped.\n";
		next;
	}
	my @gffline=split("\t", $exonRecord{$exonid});
	print O "$gffline[0]\t$gffline[1]\texon\t$gffline[3]\t$gffline[4]\t.\t$gffline[6]\t$gffline[7]\tgene_ids \"".join(",",@genesList)."\"; transcript_ids \"".join(",",@transcriptsList)."\"; exon_id \"$exonid\"; RPKM \"$exonRpkm\";\n";
}
print STDERR "Done\n";



#print Dumper \%geneRpkm;
