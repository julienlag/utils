#!/usr/bin/perl -w

use strict;
use warnings;

open BOULDER, "$ARGV[0]" or die $!;

$/="\n=\n";

#print STDOUT "## columns:\n## primer_set_id\n## fwd_primer\n## rev_primer\n## target_seq\n";
while(<BOULDER>){
	my $primerset_id;
	my $target_seq;
	my $fwd;
	my $rev;
	if($_=~/PRIMER_SEQUENCE_ID=(\S+)\n/){
		$primerset_id=$1;
	}
	unless($_=~/\nPRIMER_\S+_SEQUENCE/){
		warn "Skipped seq $primerset_id as no external set could be designed\n";
		next;
	}
	if($_=~/\nSEQUENCE=(\S+)\n/){
		$target_seq=$1;
	}
	if($_=~/\nPRIMER_LEFT_SEQUENCE=(\S+)\n/){
		$fwd=$1;
	}
	if($_=~/\nPRIMER_RIGHT_SEQUENCE=(\S+)\n/){
		$rev=$1;
	}
	print STDOUT "$primerset_id\t$fwd\t$rev\t$target_seq\n";
}
