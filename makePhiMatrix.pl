#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

#first count how many transcripts belong to each locus
my %transcriptsPerLocus = ();

#print STDERR Dumper \%transcriptsPerLocus;
open F, "$ARGV[0]" or die $!;

my %featureTofeatureCooccurrence = ();
my %featureOccurrence            = ();
my %featuresWithPositions        = ();    #used to sort features by position
my %locusToFeatures              = ();
while (<F>) {

    #print STDERR;
    chomp;
    my @line = split( " ", $_ );
    my $locusId = shift @line;    #remove first element, which is the locus id
    if ( exists( $transcriptsPerLocus{$locusId} ) ) {
        $transcriptsPerLocus{$locusId}++;
    }
    else {
        $transcriptsPerLocus{$locusId} = 1;
    }
    my @lineCopy = @line;
    foreach my $f1 (@line) {
        my @coords = split( ":", $f1 );
        @{ $featuresWithPositions{$f1} } = @coords;
        $locusToFeatures{$locusId}{$f1} = 1;
        if ( exists $featureOccurrence{$f1} ) {
            $featureOccurrence{$f1}++;
        }
        else {
            $featureOccurrence{$f1} = 1;
        }
        foreach my $f2 (@lineCopy) {
            if ( exists( $featureTofeatureCooccurrence{$f1}{$f2} ) ) {
                $featureTofeatureCooccurrence{$f1}{$f2}++;
            }
            else {
                $featureTofeatureCooccurrence{$f1}{$f2} = 1;
            }

        }
    }
}
close F;

#print STDERR Dumper \%featureOccurrence;
#print STDERR Dumper \%featureTofeatureCooccurrence;

#adjust values of co-occurrence (i.e. calculate Phi coefficient for each pair of exons)
#given a contigency table of coocurrence between exon X and Y:

#        Y-  Y+  total
#  X-    a   b   e
#  X+    c   d   f
#total   g   h   n

#  d is known (co-occurrence count)
#  f is known (number of occurrences of X)
#  h is known (number of occurrences of Y)
#  n is known (number of transcripts in locus)
#  all other values will be deduced

# phi = (ad - bc) / sqrt (efgh)
my %featureTofeaturePhi = ();

foreach my $locusId ( keys %locusToFeatures ) {
    my @featuresCopy = ();
    foreach my $f1 ( keys %{ $locusToFeatures{$locusId} } ) {
        push( @featuresCopy, $f1 );
    }
#    print STDERR join(",\n", @featuresCopy)."\n";
    foreach my $fX ( keys %{ $locusToFeatures{$locusId} } ) {

        #foreach my $fY (@featuresCopy) {
        for ( my $i = 0; $i <= $#featuresCopy; $i++ ) {
            my $fY = $featuresCopy[$i];
#            print STDERR "exon pair: $fX $fY\n";
            my ($cont_a, $cont_b, $cont_c, $cont_d, $cont_e,
                $cont_f, $cont_g, $cont_h, $cont_n
            );
            $cont_n = $transcriptsPerLocus{$locusId};
            if ( exists $featureTofeatureCooccurrence{$fX}{$fY} ) {
                $cont_d = $featureTofeatureCooccurrence{$fX}{$fY};
            }
            else {
                $cont_d = 0;
            }
            $cont_f = $featureOccurrence{$fX};
            $cont_h = $featureOccurrence{$fY};
            $cont_g = $cont_n - $cont_h;
            $cont_e = $cont_n - $cont_f;
            $cont_b = $cont_h - $cont_d;
            $cont_a = $cont_e - $cont_b;
            $cont_c = $cont_g - $cont_a;
#            print STDERR "$cont_a, $cont_b, $cont_c, $cont_d,
#            $cont_e, $cont_f, $cont_g, $cont_h, $cont_n\n";
            my $denominator=sqrt( $cont_e * $cont_f * $cont_g * $cont_h );
            $denominator=1 if($denominator == 0); # phi will be zero. This happens if an exon is always present.
            my $phi= ($cont_a * $cont_d - $cont_b * $cont_c )
                / $denominator;
                die "exon $fX vs exon $fY: phi is $phi but should be between -1 and 1. Aborting. Contingency table is\na: $cont_a, b: $cont_b, c: $cont_c, d: $cont_d, e: $cont_e, f: $cont_f, g: $cont_g, h: $cont_h, n: $cont_n\n" if ($phi< -1 || $phi > 1);
            $featureTofeaturePhi{$fX}{$fY}
                = $phi;
        }
    }
}

#print STDERR Dumper \%featureTofeatureCooccurrence;
#print STDERR Dumper \%featuresWithPositions;

my @featuresSorted;
foreach my $f (
    sort {
        $featuresWithPositions{$a}->[0] cmp $featuresWithPositions{$b}->[0]
            || $featuresWithPositions{$a}->[1]
            <=> $featuresWithPositions{$b}->[1]
            || $featuresWithPositions{$a}->[2]
            <=> $featuresWithPositions{$b}->[2]
    }
    keys %featuresWithPositions
    )
{
    push( @featuresSorted, $f );
}

#print STDERR Dumper \@featuresSorted;

my @featuresSortedCopy = @featuresSorted;
print STDOUT "featureId\t" . join( "\t", @featuresSorted ) . "\n";
foreach my $f1 (@featuresSorted) {
    print STDOUT "$f1\t";
    my @values = ();
    foreach my $f2 (@featuresSortedCopy) {
        if ( exists( $featureTofeaturePhi{$f1}{$f2} ) ) {
            push( @values, $featureTofeaturePhi{$f1}{$f2} );
        }
        else {
            push( @values, 0 );
        }
    }
    print STDOUT join( "\t", @values ) . "\n";
}
