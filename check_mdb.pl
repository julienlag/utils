#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use Text::ParseWords;
use Clone;
$|=1;


open MDB, "$ARGV[0]" or die $!;
open MASTER, "$ARGV[1]" or die $!;

my %labExpId_to_all=();
my %gen0_cell_to_labExpId=();
my @keys=();

my @important_attrs=('rnaExtract','dataType','labProtocolId','replicate','bioRep','labExpId','localization','cell');

my %localizationToLabProtocolId=(
	"cell" => "WC",
	"chromatin" => "CH",
	"nucleus" => "N",
	"nucleolus" => "NL",
	"nucleoplasm" => "NP",
	"cytosol" => "C",
	"polysome" => "P",
	);
my %rnaExtractToLabProtocolId=(
	"longNonPolyA" => "-",
	"longPolyA" => "+",
	"shortTotal" => "s",
	"total" => "t"
	);
my %dataTypeToLabProtocolId=(
	"Cage" => "cage",
	"RnaPet" => "pet",
	"RnaSeq" => ""
	);

while(<MASTER>){
	#print;
	chomp;
	my %line_attr=();
	my @line=split "\t";
	if ($_=~/^#(.+)/){
		my $l=$1;
		@keys=split("\t",$l);
		next;
	}
	for (my $i=0; $i<=$#line; $i++){
		$line_attr{$keys[$i]}=$line[$i];
	}
#	print Dumper \%line_attr;
	die "dup!" if (exists $labExpId_to_all{$line_attr{'labExpId'}});
	$labExpId_to_all{$line_attr{'labExpId'}}=\%line_attr;
	my $labProtocolId=$line_attr{'bioRep'}.$localizationToLabProtocolId{$line_attr{'localization'}}.$rnaExtractToLabProtocolId{$line_attr{'rnaExtract'}}.$dataTypeToLabProtocolId{$line_attr{'dataType'}};
	my $bioRep=$line_attr{'bioRep'}.$localizationToLabProtocolId{$line_attr{'localization'}};
	$labExpId_to_all{$line_attr{'labExpId'}}{'labProtocolId'}=$labProtocolId;
	$labExpId_to_all{$line_attr{'labExpId'}}{'bioRep'}=$bioRep;
	if($line_attr{'bioRep'} =~ /^gen0/){
		die "dup!
$line_attr{'cell'}\t$line_attr{'localization'}\t$line_attr{'rnaExtract'}\t$line_attr{'dataType'}\t$line_attr{'replicate_old'}
" if (exists $gen0_cell_to_labExpId{$line_attr{'cell'}}{$line_attr{'localization'}}{$line_attr{'rnaExtract'}}{$line_attr{'dataType'}}{$line_attr{'replicate_old'}});
		$gen0_cell_to_labExpId{$line_attr{'cell'}}{$line_attr{'localization'}}{$line_attr{'rnaExtract'}}{$line_attr{'dataType'}}{$line_attr{'replicate_old'}}=$line_attr{'labExpId'};
	}
}
#print STDERR Dumper \%labExpId_to_all;




while (<MDB>){
#	print STDERR "=\n$_";
	my $line=$_;
	my %meta=();
	my %meta_new=();
	chomp;
	my @keys=();
	my @line = quotewords('\s+', 1, $_);
	#my @line=split " ";
	my $max_lastIndex=-1; #for pooled files
	for(my $i=0; $i<=$#line; $i++){
		if($i>1){ #we've reached "key=value" pairs
			my @pair=quotewords('=', 1, $line[$i]);
			#$line[$i]=~/(\S+)=(\S+)/){
			my @val=quotewords (",",1,$pair[1]);
			push(@keys, quotewords (",",1,$pair[0]));
			$max_lastIndex= $#val if ($#val>$max_lastIndex);
			die "dup!\n" if (exists $meta{$pair[0]});
			$meta{$pair[0]}=\@val;
		}
	}
	
#	print "BEFORE: \n".Dumper \%meta;
	for (my $i=0; $i<=$#important_attrs; $i++){ # trick: populate array artificially when pooled files
		for (my $j=0;$j<=$max_lastIndex; $j++){
			$meta{$important_attrs[$i]}[$j] = $meta{$important_attrs[$i]}[$j-1] unless(defined $meta{$important_attrs[$i]}[$j])
		}
		
	}
#	print STDERR "BEFORE: \n".Dumper \%meta;
	%meta_new=%{ Clone::clone (\%meta) };
	for (my $i=0; $i<=$#important_attrs; $i++){
		for (my $j=0;$j<=$#{@meta{$important_attrs[$i]}}; $j++){
			#print "meta: ".$meta{'labExpId'}[$j]."\n";
			if (defined ($meta{'labExpId'}[$j])){
#				print STDERR "Present labExpId: cell-> ".$meta{'cell'}[$j]."\tlocalization-> ".$meta{'localization'}[$j]."\trnaExtract-> ".$meta{'rnaExtract'}[$j]."\tdataType-> ".$meta{'dataType'}[$j]."\treplicate_old-> ".$meta{'replicate'}[$j]."\n";
				#print "meta: ".$meta{'labExpId'}[$j]."\n";
				#print "master: ".Dumper \%{$labExpId_to_all{$meta{'labExpId'}[$j]}};
				#print "master $important_attrs[$i]: ".${$labExpId_to_all{$meta{'labExpId'}[$j]}}{$important_attrs[$i]}."\n";
				#print STDERR "current line: $important_attrs[$i] = $meta{$important_attrs[$i]}[$j]
#master file : $important_attrs[$i] = ${$labExpId_to_all{$meta{'labExpId'}[$j]}}{$important_attrs[$i]}
#";
				die "labExpId $meta{'labExpId'}[$j] not found in master TSV\n" unless (exists ($labExpId_to_all{$meta{'labExpId'}[$j]}));
				if(!defined ($meta{$important_attrs[$i]}[$j]) || ${$labExpId_to_all{$meta{'labExpId'}[$j]}}{$important_attrs[$i]} ne $meta{$important_attrs[$i]}[$j]){
						print STDERR "=\n$line";
						print STDERR "CONFLICT BETWEEN MDB AND MASTER TSV\n";
#CONFLICT 1 current line: $important_attrs[$i] = $meta{$important_attrs[$i]}[$j]
#CONFLICT 2 master file : $important_attrs[$i] = ${$labExpId_to_all{$meta{'labExpId'}[$j]}}{$important_attrs[$i]}\n";

				}
				$meta_new{$important_attrs[$i]}[$j]=${$labExpId_to_all{$meta{'labExpId'}[$j]}}{$important_attrs[$i]};
				#	$labExpId_to_all{$meta{'labExpId'}[$j]}."\n";
				#if ($labExpId_to_all{$meta{'labExpId'}}{$important_attrs[$i]} ne $meta{$important_attrs[$i]}){
				#	print "\nCONFLICT:\n$line\n\n".Dumper \%{$labExpId_to_all{$meta{'labExpId'}}};
				#}
				
			}
			
			else{
				unless (defined $meta{'replicate'}[$j]){
					$meta{'replicate'}[$j]=1;
					$meta_new{'replicate'}[$j]=1;

					print STDERR "=\n$line";
					print STDERR "No 'replicate' found. Set to 1.\n";
				}
				#print "imp. attr. = $important_attrs[$i]\nmeta A:\n".Dumper \%meta;
				print STDERR "Missing labExpId: cell-> ".$meta{'cell'}[$j]."\tlocalization-> ".$meta{'localization'}[$j]."\trnaExtract-> ".$meta{'rnaExtract'}[$j]."\tdataType-> ".$meta{'dataType'}[$j]."\treplicate_old-> ".$meta{'replicate'}[$j]."\n";
				$meta_new{$important_attrs[$i]}[$j]=$labExpId_to_all{$gen0_cell_to_labExpId{$meta{'cell'}[$j]}{$meta{'localization'}[$j]}{$meta{'rnaExtract'}[$j]}{$meta{'dataType'}[$j]}{$meta{'replicate'}[$j]}}{$important_attrs[$i]};
				#print "imp. attr. = $important_attrs[$i]\nmeta B:\n".Dumper \%meta;
				
			}
			
		}
	}
	#print STDERR "NEW: \n".Dumper \%meta_new;
	print "$line[0] $line[1] ";
	push(@keys,@important_attrs);
	my %seen1 = (); my @uniq1=(); foreach my $item (@keys) {push(@uniq1, $item) unless $seen1{$item}++; }

	foreach my $key (@uniq1){
		my %seen = (); my @uniq=(); foreach my $item (@{$meta_new{$key}}) {push(@uniq, $item) unless $seen{$item}++; }

		#print "$key=".join(",",@{$meta_new{$key}})." ";
		print "$key=".join(",",@uniq)." ";
	}
	print "\n";

	
}

