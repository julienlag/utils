#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use Storable  qw(dclone); 
$|=1;

open INDEX, "$ARGV[0]" or die $!;

open PARAMS, "$ARGV[1]" or die $!;

open PARAMSPERVIEW, "$ARGV[2]" or die $!;

my %params=();
my %paramsPerView=();
while (<PARAMS>){
	#print;
	chomp;
	my @line=split "\t";
	push(@{$params{$line[0]}}, split (",",$line[1]));
}

#print STDERR Dumper \%params;

while(<PARAMSPERVIEW>){
	chomp;
	my @line=split "\t";
	push(@{$paramsPerView{$line[0]}}, $line[1]);
}

#print STDERR Dumper \%paramsPerView;

while(<INDEX>){
#	print STDERR;
	chomp;
	my @line=split "\t";
	my $url=$line[0];
	my @attrs=split("; ",$line[1]);
	my %keyValues=();
	my %params_copy=();
	%params_copy= %{ dclone(\%params)};
	#print STDERR Dumper \%params_copy;
	foreach my $i (@attrs){
		$i=~s/;$//g;
		$i=~/(\S+)=(\S+)$/;
		$keyValues{$1}=$2;
	}
	
	my @importantAttrs=();
	my @extraAttrs=();
	my @subGroupAttrs=();
	foreach my $attr (@{$params_copy{'attributes'}}){
		if(exists ($keyValues{$attr})){
			push (@importantAttrs, $keyValues{$attr});
		}
		else{
			die "Died: Attribute $attr from file $ARGV[1] doesn't exist in line $. of file $ARGV[0]\n";
		}
	}
	foreach my $attr (@{$params_copy{'extraAttributes'}}){
		if(exists ($keyValues{$attr})){
			push (@extraAttrs, $keyValues{$attr});
		}
		else{
			warn "Attribute $attr from file $ARGV[1] doesn't exist in line $. of file $ARGV[1]\n";
		}
	}
	foreach my $attr (@{$params_copy{'subGroupAttributes'}}){
		if(exists ($keyValues{$attr})){
		   my $attrDisplay=$attr;
		   $attrDisplay=~s/^cell$/bioSample/g;
		   my $valueDisplay=$keyValues{$attr};
		   if($attr eq 'replicate'){
		    $valueDisplay='rep'.$valueDisplay;
		   }
		push (@subGroupAttrs, "$attrDisplay=$valueDisplay");
		}
		else{
			warn "Attribute $attr from file $ARGV[1] doesn't exist in line $. of file $ARGV[1]\n";
		}
	}
	print "\n";
	print "track ".join('',@importantAttrs)."\n";
	print "bigDataUrl $url\n";
	print "subGroups ".join(' ', @subGroupAttrs)."\n";
	
  #subGroups view=PlusRawSig bioSample=GM12878 localization=CELL rnaExtract=TOTAL rep=rep1
	foreach my $i (@{$params_copy{'shortLabel'}}){
		#print STDERR "\n\ni = $i\n";
		if($i =~ /^\$(\S+)$/){
		#	print STDERR "\n\n\ndollar1=$1;\n\n";
			$i=$keyValues{$1};
		}
	}
	print "shortLabel ".join(' ', @{$params_copy{'shortLabel'}})."\n";
	print "longLabel ".join(' ',@importantAttrs);
	if(@extraAttrs){ #if not empty
		print " (".join(' ',@extraAttrs).")";
	}
	print "\n";

	if (exists $paramsPerView{$keyValues{'view'}}){
		print join("\n", @{$paramsPerView{$keyValues{'view'}}})."\n";
	}
#	if($keyValues{'view'} eq 'Contigs'){
#		print "visibility dense\n"
#	}
#	elsif($keyValues{'view'} eq 'Alignments'){
#		print "visibility hide\n"
#	}
	print "type $keyValues{'type'}\n";
	print "parent @{$params_copy{'parent'}}\n";
}
