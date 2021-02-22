#!/usr/bin/perl -w

use warnings;
use strict;
use Data::Dumper;

##############
### input: ###
##############
# $ARGV[0] a GTF file containing the primers and their coords on their target seqs:
#
#ENST00000414676.1       primer3 3pRacePrimer    190     214     .       +       .       ENST00000414676.1.3p.9; primerSeq "tgaacttggaactggggctactggg"; primerRank "9"; primerTm "70.088"; primerGcContent "56.000"; predictedAmpliconLength "561"; targetSeq "GGACGCGAGCCTGCTTCCATCTGACGCTGGACGCTTGTCCCTGCCCCGCGTTGCCTTTTAAATTTTAGCTCATTCCGAGACACCTGCCGTCAGACATTTATGCAGTGTGTGATTCTTTCTAAAACAACTCCCTGGAAGAGAGGACATttaattcaacaatttattggccacctactgtgcaccaggcagtgaacttggaactggggctactgggttacagcagtgaccaagacagaggtccctgttcttaaggagcaagtgagggcaacagaaaagagcagtcagctgtcatgcgagggcactcaagcagccctgtggaaagctctacgtggtgagaaactgaagcctcctgccaacaccaacaaggaactgagacctacttccaacagccatctgagtgatcgatccatcctggaatcagatcctccagccccagtcaagtcttcagatgactgcagccctgaccagcatctcaactgcaacctcgtgaatgaccctgagccagaaccatgcaactaaactctgcgtggattcatgacccacagaaactgtgagatggtagctgtttgctttgttaagcctctaagtctggaaagaatgtcttaagcagtagcagacaatgaacacaAGATTATTATTCAGCTGTTGAATTGGAAGAGGAGGGGAAGAAAAAATTTTCAGATCACAAAATATTCATTGTGTAAAACTTCAAAAATTCTGAAATTTAAGGAAAAAATATCATTTGTTGGG";
#ENST00000414676.1       primer3 3pRacePrimer    274     298     .       +       .       ENST00000414676.1.3p.15; primerSeq "aagagcagtcagctgtcatgcgagg"; primerRank "15"; primerTm "70.156"; primerGcContent "56.000"; predictedAmpliconLength "477"; targetSeq "GGACGCGAGCCTGCTTCCATCTGACGCTGGACGCTTGTCCCTGCCCCGCGTTGCCTTTTAAATTTTAGCTCATTCCGAGACACCTGCCGTCAGACATTTATGCAGTGTGTGATTCTTTCTAAAACAACTCCCTGGAAGAGAGGACATttaattcaacaatttattggccacctactgtgcaccaggcagtgaacttggaactggggctactgggttacagcagtgaccaagacagaggtccctgttcttaaggagcaagtgagggcaacagaaaagagcagtcagctgtcatgcgagggcactcaagcagccctgtggaaagctctacgtggtgagaaactgaagcctcctgccaacaccaacaaggaactgagacctacttccaacagccatctgagtgatcgatccatcctggaatcagatcctccagccccagtcaagtcttcagatgactgcagccctgaccagcatctcaactgcaacctcgtgaatgaccctgagccagaaccatgcaactaaactctgcgtggattcatgacccacagaaactgtgagatggtagctgtttgctttgttaagcctctaagtctggaaagaatgtcttaagcagtagcagacaatgaacacaAGATTATTATTCAGCTGTTGAATTGGAAGAGGAGGGGAAGAAAAAATTTTCAGATCACAAAATATTCATTGTGTAAAACTTCAAAAATTCTGAAATTTAAGGAAAAAATATCATTTGTTGGG";
#mandatory attrs. (9th field) are ID (*must* be the first one), primerRank, predictedAmpliconLength

# $ARGV[1] desired size range of amplicons, e.g. "500-700"

##############
### output ###
##############
# one primer (GFF line) corresponding to best primer according to size range (given in $ARGV[1]) and primerRank


die "Didn't understand desired amplicon size\n" unless ($ARGV[1] =~ /^(\d+)$/);
my $desiredAmpliconLength=$1;

open GFF, "$ARGV[0]" or die $!;


my %primerGffLine=();
my %primerRank=();
#my %primerPredictedAmpliconLength=();
my %primerDistToDesiredAmpliconLength=();
my %targetId2primerList=();
while(<GFF>){
	#print;
	chomp;
	my $line=$_;
	my @line=split "\t";
	my @attrs=split("; ", $line[8]);
	$primerGffLine{$attrs[0]}=$line;
	push(@{$targetId2primerList{$line[0]}}, $attrs[0]);
	foreach my $attr (@attrs){
		#print "$attr\n";
		#print Dumper \%primerRank;
		if($attr=~/primerRank "(\d+)"/){
			die "Duplicate line $.!!\n$line\n" if (exists $primerRank{$attrs[0]});
			$primerRank{$attrs[0]}=$1;
		}
		elsif($attr=~/predictedAmpliconLength "(\d+)"/){
			die "Duplicate line $.!!\n$line\n" if (exists $primerDistToDesiredAmpliconLength{$attrs[0]});
			#$primerPredictedAmpliconLength{$attrs[0]}=$1;
			$primerDistToDesiredAmpliconLength{$attrs[0]}=abs($1-$desiredAmpliconLength);
		}
	}
	die "primerRank and predictedAmpliconLength are mandatory attributes\n" unless (exists $primerDistToDesiredAmpliconLength{$attrs[0]} && exists $primerRank{$attrs[0]});
}
#print Dumper \%targetId2primerList;


foreach my $target (keys %targetId2primerList){
	foreach my $primer (sort { $primerDistToDesiredAmpliconLength{$a} <=> $primerDistToDesiredAmpliconLength{$b} || $primerRank{$a} <=> $primerRank{$b} }  @{$targetId2primerList{$target}}){
		print "$primerGffLine{$primer}\n";
		last;
	}
}
