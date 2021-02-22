#!/usr/bin/perl -w
use strict;
use warnings;
use lib "/users/rg/jlagarde/julien_utils/";
use encode_metadata;
use Data::Dumper;
use Getopt::Long;
#use Getopt::Long qw(:config debugh);
$|=1;


#reads BAM entries of a UCSC/ENCODE DCC index file as input

# ONLY ONE "composite" (e.g. 'wgEncodeUwRnaSeq') at a time!!! (arg #1)

my $composite=$ARGV[0];
my $filepath=$ARGV[1];
my $viewName2fileName=$ARGV[2];
die unless $#ARGV==2;
open V2F, "$viewName2fileName" or die  $!;
my %viewN2fileN=();
while (<V2F>){
	chomp;
	my @line=split "\t";
	$viewN2fileN{$line[0]}=$line[1];
}
close V2F;

print STDERR "composite: $composite\n";
#print STDERR "grepping BAM file entries\n";
#open F, "fgrep 'view=Alignments;' $filepath|grep 'type=bam;'|" or die $!;
open F, "$filepath" or die $!;

while(<F>){
	#print;
	chomp;
	my $line=$_;
	my @line=split "\t";
	my @attributes=split("; ", $line[1]);
	#print STDERR "\n@attributes\n";
	my %attr=();
	foreach my $at (@attributes){
		if($at=~/(\S+)=(.+)/){
			$attr{$1}=$2;
		}
		else{
			die "badly formatted key=value pair: $at\n";
		}
	}
	unless (exists $viewN2fileN{$attr{'view'}}){
		print STDERR "Skipped line $., view $attr{'view'} not registered in $viewName2fileName.\n";
		next;
	}
		#skip line if view is not registered in $viewName2fileName
	#print STDERR Dumper \%attr;
	if (exists $attr{'composite'}){
		if ($attr{'composite'} ne $composite){
			die "Line $.: composite is different from the one specified as argument. Cannot continue.\n"
		}
	}
	unless(exists $attr{'labExpId'} &&  $attr{'labExpId'} ne ''){
		#print STDERR "labExpId not defined, generating one\n";
		my $newlabExpId=undef;
		if (exists $attr{'tableName'} && $attr{'tableName'}=~/$composite(\S+)$viewN2fileN{$attr{'view'}}(\S+)$/){
			#$attr{'tableName'}=~/$composite(\S+)Aln(\S+)$/;
			$newlabExpId=$composite.$1.$2;
			#print STDERR "$newlabExpId\n";
			print $line."; labExpId=$newlabExpId;\n"
		}
		else{
			print STDERR "Can't find tableName attribute to make up a labExpId.\nOffending line (will be absent from output):\n$line\n";
			next; 
		}
	}
	else{
		print $line."\n";
	}
#	wgEncodeUwRnaSeqThymusCellPolyaMAdult8wksC57bl6AlnRep1.bam      project=wgEncode; grant=Stam; lab=UW-m; composite=wgEncodeUwRnaSeq; dataType=RnaSeq; view=Alignments; cell=Thymus; strain=C57BL/6; sex=M; age=adult-8wks; localization=cell; rnaExtract=polyA; replicate=1; dataVersion=ENCODE Mar 2012 Freeze; dateSubmitted=2011-12-22; dateUnrestricted=2012-09-22; subId=5340; labVersion=ABI BioScope v1.2.1; tissueSourceType=Pooled; tableName=wgEncodeUwRnaSeqThymusCellPolyaMAdult8wksC57bl6AlnRep1; type=bam; md5sum=b1afe744eb76c97be1ddabd0b242a5f6; size=1.4G


}
