#!/usr/local/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
my $boulderfilename=$ARGV[0];
my $racetype=$ARGV[1];
die "Need to know race type ('5' or '3') as second argument\naborted\n" unless ($racetype == 5 || $racetype == 3);
open PRIMERS, "$boulderfilename" or die $!;
open GFF, ">$boulderfilename.$racetype.gff" or die $!;
my $targetid='';
my $chr='';
my $start_target='';
my $stop_target='';
my $str_target='';
while (<PRIMERS>){
	my $primerrank='';
	my $primerseq='';
	my $primertype='';
	my $tm='';
	my $size='';
	my $gc_pc='';
	
	if ($_=~/^=$/){
		next;
	}
	if ($_=~/PRIMER_SEQUENCE_ID=(\S+)\n/){
		$targetid=$1;
		$targetid=~/(chr\S+)_(\d+)_(\d+)_(p|m|n)/;
		$chr=$1;
		$start_target=$2;
		$stop_target=$3;
		$str_target=$4;
	}
	
	
	elsif($_=~/PRIMER_([A-Z_]+)_SEQUENCE=(\S+)\n/){
		$primerrank=0;
		$primertype=$1;
		$primerseq=$2;
		
		if($racetype==5){
			$primerseq=reverse($primerseq);
			$primerseq=~tr/ACGTacgt/TGCAtgca/;
		}
				print STDOUT ">".$targetid."_primer_$racetype"."race_"."$primerrank\n$primerseq\n";
	}
	elsif($_=~/PRIMER_([A-Z_]+)_(\d+)_SEQUENCE=(\S+)\n/){
		$primerrank=$2;
		$primertype=$1;
		$primerseq=$3;
		if($racetype==5){
			$primerseq=reverse($primerseq);
			$primerseq=~tr/ACGTacgt/TGCAtgca/;
		}
		print STDOUT ">".$targetid."_primer_$racetype"."race_"."$primerrank\n$primerseq\n";
	}
	elsif($_=~/PRIMER_([A-Z_]+)=(\d+),(\d+)\n/){
		my $startontrans=$2;
		my $length=$3;
		$primerrank=0;
		my $endontrans=$startontrans+$length;
		my $startonchr='';
		my $endonchr='';
		if($str_target eq 'p' || $str_target eq 'n'){
			$startonchr=$start_target+$startontrans;
			$endonchr=$startonchr+$length+1;
		}
		if($str_target eq 'm'){
			$startonchr=$stop_target-($startontrans+$length)+1;
			$endonchr=$stop_target-$startontrans;
		}
		print GFF "$chr\tprimer_$racetype"."prace\tprimer\t$startonchr\t$endonchr\t$primerrank\t.\t.\t".$targetid."_primer_$racetype"."race_"."$primerrank\n";
	}
	elsif($_=~/PRIMER_([A-Z_]+)_(\d+)=(\d+),(\d+)\n/){
		my $startontrans=$3;
		my $length=$4;
		$primerrank=$2;
		my $endontrans=$startontrans+$length;
		my $startonchr='';
		my $endonchr='';
		if($str_target eq 'p' || $str_target eq 'n'){
			$startonchr=$start_target+$startontrans;
			$endonchr=$startonchr+$length+1;
		}
		if($str_target eq 'm'){
			$startonchr=$stop_target-($startontrans+$length)+1;
			$endonchr=$stop_target-$startontrans;
		}
		print GFF "$chr\tprimer_$racetype"."prace\tprimer\t$startonchr\t$endonchr\t$primerrank\t.\t.\t".$targetid."_primer_$racetype"."race_"."$primerrank\n";
		
	}
}
