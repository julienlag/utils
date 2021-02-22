#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
$|=1;

#arg1 = file containing ordered list of feature_ids
#arg2 = file containing list of GTFs where to find the RPKMs to report, in ./flux_out/
#arg3 = feature type (transcript _id or gene_id)

my $feat_ids = $ARGV[0];
my $gtf_list = $ARGV[1];
my $feature_type= $ARGV[2];
my %labExpIdToGTF=();
my %feature_idTolabExpIdToRPKM=();
open GTFLIST, "$gtf_list" or die $!;
while(<GTFLIST>){
	chomp;
	my $path=$_;
	#print "$path\n";
	my @path=split("/", $path);
	my $filename=$path[$#path];
	$filename=~/(\S+?)\.\S+/;
	my $labExpId=$1;
	#print $labExpId."\n";
	if(exists $labExpIdToGTF{$labExpId}){
		warn "Duplicate file found for $labExpId. Only the last one encountered will be considered\n";
	}
	$labExpIdToGTF{$labExpId}=$path;
}
print STDERR Dumper \%labExpIdToGTF;
close GTFLIST;

foreach my $labExpId (keys %labExpIdToGTF){
	print STDERR "Processing $labExpIdToGTF{$labExpId}\n";
	open GTF, "$labExpIdToGTF{$labExpId}" or die "$labExpIdToGTF{$labExpId}: $!";
	while (<GTF>){
		chomp;
		$_=~/$feature_type \"*(\S+)\"*;/;
		my $feature_id=$1;
		$_=~/RPKM \"*(\S+)\"*/;
		my $RPKM=$1;
		$RPKM=~s/;//;
		$RPKM=~s/"//;
		$feature_id=~s/;//;
		$feature_id=~s/"//;
		if(exists $feature_idTolabExpIdToRPKM{$feature_id}{$labExpId}){
			warn "Duplicate entry found for $feature_id in $labExpId. Only the last one encountered will be considered\n";
		}
		$feature_idTolabExpIdToRPKM{$feature_id}{$labExpId}=$RPKM;
	}
	close GTF;
}
#print STDERR Dumper \%feature_idTolabExpIdToRPKM;
my @sortedLabExpIds=();
foreach my $labExpId (sort keys %labExpIdToGTF){
	push (@sortedLabExpIds, $labExpId)
}
#print header
print "feature_id\t".join ("\t", @sortedLabExpIds)."\n";
open F, "$feat_ids" or die $!;
while(<F>){
	#print corresponding hash content
	chomp;
	my $feature_id=$_;
	my @rpkms=();
	foreach my $lid (@sortedLabExpIds){
		if(exists $feature_idTolabExpIdToRPKM{$feature_id}{$lid}){
			push(@rpkms, $feature_idTolabExpIdToRPKM{$feature_id}{$lid});
		}
		else{
			warn "$feature_id not found in $lid. Set to 0.\n";
			push(@rpkms, 0);
		}
	}
	print "$feature_id\t".join ("\t", @rpkms)."\n";
}
close F;
