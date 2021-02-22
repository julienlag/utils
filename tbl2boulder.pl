#!/usr/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
use diagnostics;
my $tblfilename= $ARGV[0];
my $paramfile= $ARGV[1];


#open PARAMS, "$paramfile" or die $!;
#$/="";
#my $params=<PARAMS>;
#chomp $params;
#close PARAMS;
#$/="\n";
open TBL, "$tblfilename" or die $!;
while(<TBL>){
	if($_=~/(\S+) (\S+)/){
		
		my $id= $1;
		#my $idregexp=quotemeta($id);
		#print STDERR "$id ";
		my $seq= $2;
		#print STDOUT "PRIMER_SEQUENCE_ID=$id\nSEQUENCE=$seq\n$params\n=\n";
		print STDOUT "SEQUENCE_ID=$id\nSEQUENCE_TEMPLATE=$seq\n";
		open PARAMS, "$paramfile" or die $!;
		while(<PARAMS>){
			#my $foundtarget=0;
			#my $globalparam;
			#my $targetparam;
			if($_=~/^\S+\s*=.+\n/){ #boulder primer3 params encountered
				#$globalparam.=$_;
				print STDOUT;
			}
			elsif($_=~/^$id\t(\S+\s*=.+\n)/){ #boulder primer3 extra params encountered for $id
				
				print STDOUT $1;
			}
		}
		print STDOUT "=\n"; # end of boulder record
		close PARAMS;
	}
	
	
	
	else{
		print STDERR "Malformed line: $_";
	}
}

