#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
$|=1;

my $indexFile=$ARGV[0];
my $pathToConverter=$ARGV[1]; #path to full2relativepath converter (e.g. /users/rg/jlagarde/julien_utils/relativepath.sh)
my $ucsc_db=$ARGV[2];

my %lid2acc=();
if(defined ($ARGV[3])){
	my $lid2acc=$ARGV[3];
	open MAP, "$lid2acc", or die $!;
	while(<MAP>){
		chomp;
		my @line=split "\t";
		$lid2acc{$line[1]}=$line[0];
		$lid2acc{$line[2]}=$line[0];
	}
close MAP;
}
open INDEX, "$indexFile", or die $!;

print "#file_name\tformat\toutput_type\texperiment\treplicate\tenriched_in\tucsc_db\tpaired_end\n";

while(<INDEX>){
  chomp;
  my @line=split "\t";
  my $url=$line[0];
  my $relativeUrl=`$pathToConverter $url`;
  chomp($relativeUrl);
  my $fileName=$relativeUrl;
  $fileName=~s/\.gz$//g;
  $fileName=~s/\.tgz$//g;
  #print STDERR "$fileName\n";
  my @fileName=split(/\./, $fileName);
    #print STDERR "$fileName $#fileName\n";
  my $fileExt=$fileName[$#fileName];
  $line[1]=~/replicate=(\S+);/;
  my $rep=$1;
  $line[1]=~/labExpId=(\S+);/;
  my $labExpId=$1;
  $line[1]=~/dccExpAcc=(\S+);/;
  my $dccExpAcc=$1;
  $lid2acc{$labExpId}=$dccExpAcc;
  $line[1]=~/view=(\S+);/;
  my $view=$1;
  my $output_type=undef;
  my $paired_end="n/a";
  if($view=~/FastqRd(\d)/){
    $paired_end=$1;
	$output_type="reads";
    }
  elsif($view eq 'RawData'){
	  $output_type="reads";
  }
  elsif($view eq 'PlusRawSignal'){
	  $output_type="plusSignal";
  }
  elsif($view eq 'MinusRawSignal'){
	  $output_type="minusSignal";
  }

elsif($view eq 'MultiMinusRawSignal'){
    $output_type="MultiMinus";
  }
elsif($view eq 'MultiPlusRawSignal'){
    $output_type="MultiPlus";
  }
elsif($view eq 'MultiSignal'){
    $output_type="MultiSignal";
  }
  elsif($view eq 'UniqueMinusRawSignal'){
    $output_type="UniqueMinus";
  }
elsif($view eq 'UniquePlusRawSignal'){
    $output_type="UniquePlus";
  }
elsif($view eq 'UniqueSignal'){
    $output_type="UniqueSignal";
  }

  elsif($view eq 'Alignments'){
	  $output_type="alignments";
  }
  else{
    warn "Incorrect 'view' at line $.\n"
  }
  unless (exists $lid2acc{$labExpId}){
  warn "$labExpId not found in map file. Line skipped.\n";
  next;
  }
  print "$relativeUrl\t$fileExt\t$output_type\t$lid2acc{$labExpId}\t$rep\texon\t$ucsc_db\t$paired_end\n"
}
