#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Getopt::Long;
use Pod::Usage;
$|=1;

my $message_text  = "Error\n";
my $exit_status   = 2;          ## The exit status to use
my $verbose_level = 99;          ## The verbose level to use
my $filehandle    = \*STDERR;   ## The filehandle to write to
my $sections = "NAME|SYNOPSIS|DESCRIPTION";

# =head1 NAME

# samToPolyA

# =head1 SYNOPSIS

# A utility to detect poly-adenylated sequencing reads, call on-genome polyA sites and infer the reads' strand based on reads-to-genome alignments in SAM format.

# B<Usage example> (on a BAM file):

# C<< samtools view $file.bam |samToPolyA.pl --minClipped=20 --minAcontent=0.9  - > ${file}_polyAsites.bed >>


# =head2 INPUT

# Read-to-genome alignments in SAM format, and the corresponding genome sequence in multifasta.

# The script looks for terminal soft-clipped A/T sequences (marked as "S" in the CIGAR string).

# =head2 OPTIONS

# This script maps polyA sites on the genome based on read mappings in SAM format, and according to the following provided parameters:

# =over

# =item B<minClipped> (integer) = minimum length of A or T tail required to call a PolyA site.

# Default: '10'.

# =item B<minAcontent> (float) = required A (or T, if minus strand) content of the tail.

# Default: '0.8'.

# Note: minAcontent affects both the A tail and the upstream A stretch.

# =item B<discardInternallyPrimed> = when enabled, the program will try to avoid outputting false polyA sites arising from internal mis-priming during the cDNA library construction. This option is particularly useful if your cDNA was oligo-dT primed.

# Default: disabled.

# Requires option B<genomeFasta> to be set.

# =item B<minUpMisPrimeAlength> (integer) (ignored if B<discardInternallyPrimed> is not set) = minimum length of genomic A stretch immediately upstream a putative site required to call a false positive (presumably due to internal RT priming), and hence not report the corresponding site in the output.

# Default: '10'.

# =item B<genomeFasta> (string) (valid only if B<discardInternallyPrimed> is set)= path to multifasta of genome (+ spike-in sequences if applicable), used to extract upstream genomic sequence.

# B<Note>: You need write access to the directory containing this file, as the included Bio::DB::Fasta module will create a genomeFasta.index file if it doesn't exist.

# =back

# =head2 OUTPUT

# The script will output BED6 with the following columns:

# =over

# =item column 1: chromosome

# =item column 2: start of polyA site (0-based)

# =item column 3: end of polyA site

# =item column 4: ID of the read containing a polyA tail

# =item column 5: length of the polyA tail on read

# =item column 6: genomic strand of the read (see DESCRIPTION below)

# =back

# =head1 DESCRIPTION

# The script will search for read alignment patterns such as:


# C<< XXXXXXXXXXXAAAAAAAAAAAAAAA(YYYY) [read] >>

# C<< |||||||||||..................... [match] >>

# C<< XXXXXXXXXXXZ-------------------- [reference sequence] >>

# or

# C<< (YYYY)TTTTTTTTTTTTTTTTXXXXXXXXXX [read] >>

# C<< ......................|||||||||| [match] >>

# C<< ---------------------ZXXXXXXXXXX [reference sequence] >>

# Where:

# =over

# =item C<|> / C<.> = a position mapped / unmapped to the reference, respectively

# =item C<X> = the mapped portion of the read or reference sequence

# =item C<(Y)> = an optional soft-clipped, non-(A|T)-rich sequence (possibly a sequencing adapter)

# =item C<Z> = the position on the reference sequence where the alignment breaks

# =item The C<A> / C<T> streches are soft-clipped ('S' in CIGAR nomenclature) in the alignment

# =item C<-> = the portion of the reference sequence unaligned to the read

# =back

# The genomic strand of the read + polyA site is inferred from the mapping of the read, I<i.e.>, reads where a polyA tail was detected at their 3' end are assigned a '+' genomic strand, whereas reads with a polyT tail at their 5' end are deduced to originate from the '-' strand. In that example, the first / second alignment would lead to a called polyA site at position Z on the '+' / '-' strand of the reference sequence, respectively.

# =head1 DEPENDENCIES

# CPAN: Bio::DB::Fasta

# =head1 AUTHOR

# Julien Lagarde, CRG, Barcelona, contact julienlag@gmail.com

# =cut



my $meanQualCutoff=0;
my $window=3; #+/- $window of exonic bases will be extracted around each intron

GetOptions ('slop=i' => \$window,
            'minQual=i' => \$meanQualCutoff)
  or pod2usage( { -message => "Error in command line arguments",
        		  -exitval => $exit_status  ,
            		-verbose => $verbose_level,
               -output  => $filehandle } );

unless(defined $window && defined $meanQualCutoff && $window >=0 ){
	pod2usage( { -message => "Error in command line arguments",
        		  -exitval => $exit_status  ,
            		-verbose => $verbose_level,
               -output  => $filehandle } );
}


REC: while (<>){
	my $line=$_;
	chomp;
	if($_=~/^\@(HD|SQ|RG|PG)(\t[A-Za-z][A-Za-z0-9]:[ -~]+)+$/ || $_=~/^\@CO\t.*/){ #skip sequence header
		print "$line";
		next REC;
	}
	my @line=split "\t";
	die "Invalid format (doesn't look like SAM)\n" unless ($#line>9);
	next if($line[5] eq '*'); #skip unmapped reads
	#print "$line[0]\n";
	my @cigarNumbers=split (/[A-Z]/,$line[5]);
	my @cigarLetters=split(/\d+/,$line[5]);
	shift(@cigarLetters); #the first element is empty, remove it
	my @qualsAscii=split("", $line[10]);
	my @seq=split("", $line[9]);
	my @quals=();
	foreach my $qual (@qualsAscii){
		push(@quals, ord($qual) -33 ); # see https://en.wikipedia.org/wiki/FASTQ_format#Quality
	}
	@qualsAscii=();
	#print @cigarLetters."\n";
	#print @cigarNumbers."\n";
	#print join (" ", @cigarLetters)."\n";
	#print join (" ", @cigarNumbers)."\n";
	#print join (" ", @quals)."\n";

	my $position=0;
	for (my $i=0; $i<=$#cigarLetters; $i++){
		if($cigarLetters[$i] eq 'M' || $cigarLetters[$i] eq 'I' || $cigarLetters[$i] eq 'S' || $cigarLetters[$i] eq '=' || $cigarLetters[$i] eq 'X' ){
			$position+=$cigarNumbers[$i];
		}
		elsif($cigarLetters[$i] eq 'N'){ #intron!
			my $windowMin=$position-$window;
			my $windowMax=$position+$window;
			$windowMin=0 if $windowMin<0;
			$windowMax=$#seq if $windowMax > $#seq;
			#print join ("", @seq[$windowMin..$position-1])." / ". join("",@seq[$position..$windowMax-1])."\n";
			my $sumQualScores=0;
			my $countBases=0;
			foreach my $qual (@quals[$windowMin..$position-1]) {
				$countBases++;
				$sumQualScores+=$qual;
			}
			foreach my $qual (@quals[$position..$windowMax-1]) {
				$countBases++;
				$sumQualScores+=$qual;
			}
			my $meanQual=$sumQualScores/$countBases;
			#print "$meanQual ($sumQualScores / $countBases)\n";
			if ($meanQual<$meanQualCutoff){
				next REC;
			}
		}
	}
	print "$line"; #also print all monoexonic reads
}
