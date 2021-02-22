#!/usr/bin/perl -w
use strict;
use strict 'refs';
use warnings;
use Data::Dumper;
$|=1;
my %labExpId_attrs=();
my %metadata=();
my %dataTypeToViewsInventory=();
my %labExpIdToDataType=();
while(<>){
	#print;
	my $line=$_;
	chomp;
#	my %metadata=();
	my @line=split "\t";
	$line[1]=~s/ //g;
	my @attrs=split(";", $line[1]);
	#print "\n@attrs\n";
	my $labExpId=undef;
	foreach my $attr (@attrs){
		$attr=~/(\S+)=(\S+)/;
		$metadata{$.}{$1}=$2;
	}
	$metadata{$.}{'url'}=$line[0];
	next if($metadata{$.}{'type'} eq 'bai');
	if(!exists $metadata{$.}{'labExpId'}){
		warn "labExpId attribute not found. Skipped line # $.: $line";
		next;
	}
	elsif(!exists $metadata{$.}{'view'}){
		warn "view attribute not found. Skipped line # $.: $line";
		next;
	}
	elsif(!exists $metadata{$.}{'dataType'}){
		warn "dataType attribute not found. Skipped line # $.: $line";
		next;
	}
	else{
		#print Dumper \%metadata;
		#split labExpIds if pooled
		my @labExpIds=split(",", $metadata{$.}{'labExpId'});
		#my $metadata_ref= \%{$metadata{$.}};
#		print "labExpId before split: $metadata{$.}{'labExpId'}\n";
		$dataTypeToViewsInventory{$metadata{$.}{'dataType'}}{$metadata{$.}{'view'}}=1;
		foreach my $leid(@labExpIds){
#			print "labExpId: $leid\n".Dumper \%{$metadata{$.}};
			#push(@{$labExpId_attrs{$leid}{$metadata{$.}{'view'}}},$metadata_ref);
			#$labExpId_attrs{$leid}{$metadata{$.}{'view'}}=%metadata;
			#print $leid.Dumper \%{$labExpId_attrs{$leid}}
			push(@{$labExpId_attrs{$leid}{$metadata{$.}{'view'}}}, \%{$metadata{$.}});
			$labExpIdToDataType{$leid}=$metadata{$.}{'dataType'};
			#$labExpId_attrs{$leid}{$metadata{$.}{'view'}}= \%{$metadata{$.}};
#			print "Current dump:\n".Dumper \%labExpId_attrs;

		}
	}
}
#print "hash dump\n";
#print Dumper \%labExpId_attrs;
#print "dataTypeToViewsInventory\n".Dumper \%dataTypeToViewsInventory;
my %missingViews=();
 foreach my $labExpId (keys %labExpId_attrs){
	 #print "\n$labExpId\t";
 	#foreach my $view (keys %{$labExpId_attrs{$labExpId}}){
	 my @views=();
	 foreach my $view (keys %{$dataTypeToViewsInventory{$labExpIdToDataType{$labExpId}}}){ #list all available views encountered in the input file for labExpId's dataType
		 #print "view=$view\t";
		 my @files=();
		 if(exists $labExpId_attrs{$labExpId}{$view}){
			 #my @files=();
			 foreach my $file (@{$labExpId_attrs{$labExpId}{$view}}){
				 push(@files, ${$file}{'url'});
			 }
			 my $viewString="$view=".join(",", @files);
			 push(@views, $viewString);
		 }
		 else{
			 push(@views, "$view=.");
			 #print STDERR "view '$view' not found for labExpId '$labExpId'\n";
			 push(@{$missingViews{$view}}, $labExpId);
		 }
		
# 		if ($#{$labExpId_attrs{$labExpId}{$view}}>0){ #error: duplicate record for $view found!!
# 			print STDERR "Duplicate found for labExpId = $labExpId view=$view: @{$labExpId_attrs{$labExpId}{$view}}\n"
# 		}
	 }
	 #print join("\t",@views)."\n";
}
#print STDERR Dumper \%missingViews;
open O, ">missing_views.tsv" or die $!;
foreach my $view (keys %missingViews){
	@{$missingViews{$view}}= sort { $a cmp $b } @{$missingViews{$view}};
	print O "$view\t".join("\t", @{$missingViews{$view}})."\n";
}

print STDERR "Output in 'missing_views.tsv'\n";

#print Dumper \%metadata;

#print Dumper \%labExpId_attrs;

#foreach my $view (keys %{${labExpId_attrs{'K14'}}}){
#	print "$view\n";
	
#}

#print "K15:\n".Dumper \%{${labExpId_attrs{'K15'}}};

