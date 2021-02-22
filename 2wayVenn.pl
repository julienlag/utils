#!/usr/local/bin/perl -w

use strict;
use warnings;
use diagnostics;
use Data::Dumper;


# ### create dir where to write R scripts and PS plots:
# $ mkdir r
# ### generate postscript Venns:
# # individual_nt_coverage.tsv format: {set1 name} {tab} {total elements of set1}
# # All_INTERSECTION.out format: {set1 name} {tab} {set2 name} {tab} {number of elements in intersection}
# # what 2wayVenn.pl does:
# # 1- creates hashes corresponding to all sets and intersections
# # 2- computes the complement of each set
# # 3- for each intersection, generates an R script meant to output a PS plot(using the Vennerable R library)
# # 4- calls the R script
# # 5- modifies the postscript file's colors (this is ugly coding, don't look at it you might get blind)
# $ perl 2wayVenn.pl individual_nt_coverage.tsv All_INTERSECTION.out
# # convert PSs to PNGs
# $ for file in `ls *.ps`; do convert $file $file.png; done
# #make montage
# $ montage -geometry +4+4 *.png venn_montage.png













open INDIV, "$ARGV[0]" or die $!;

my %indiv=();

while(<INDIV>){
	chomp; 
	my @line=split "\t"; 
	#if($line[0]=~/_$/){
	#	chop $line[0]; #trailing "_" after gff file extension
	#}
	$indiv{$line[0]}=$line[1]
}

#print Dumper \%indiv;

open INTERSECT, "$ARGV[1]" or die $!;
my %intersect=();
while(<INTERSECT>){
	chomp; 
	my @line=split "\t"; 
	unless (exists($intersect{$line[1]}{$line[0]})){
		
		$intersect{$line[0]}{$line[1]}=$line[2];
	}
}
#print Dumper \%intersect;

foreach my $set1 (keys %indiv){
	print "$set1\n";
	foreach my $set2 (keys %{$intersect{$set1}}){
		print "$set1 $set2\n";
		my $intersect=sprintf("%.1f",$intersect{$set1}{$set2});
		my $set1complement=sprintf("%.1f",$indiv{$set1}-$intersect);
		my $set2complement=sprintf("%.1f",$indiv{$set2}-$intersect);
		my $rout="$set1"."_vs_"."$set2.r";
		my $psfile=$rout.".ps";
		open ROUT, ">./venn/$rout" or die $!;
		print ROUT "library(Vennerable)
Vcombo <- Venn(SetNames = c(\"$set1\",\"$set2\"),Weight = c(0, $set1complement, $set2complement, $intersect))
postscript(file = \"$psfile\");
tpx = trellis.par.get(\"superpose.polygon\")
tpx\$col <- c(\"black\",\"#6B6BFF\",\"#FFFF6B\",\"#C0C08F\")
trellis.par.set(\"superpose.polygon\",tpx); 
plot(Vcombo, doWeights = TRUE, doEuler = TRUE, add = TRUE, show = list(universe = FALSE, dark.matter = FALSE, Faces = TRUE));
dev.off()
";
		close ROUT;
		`cd ./venn; R --vanilla < $rout`;
 		open PS, "./venn/$psfile" or die $!;
 		my $psnew=$psfile.".new";
 		open PSNEW, ">./venn/$psnew" or die $!;
 		$/="";
 		while(<PS>){
 			$_=~s/ .5 0 0 t\n0.4196 0.4196 1 rgb/ .5 0 0 t\n0 setgray/g; #change text color of right set to black
 			$_=~s/cp p2\n0 setgray\n0.75 setlinewidth/cp p2\n1 setgray\n0.75 setlinewidth/g; #change color of both circle lines to white 
			$_=~s/c p1\n0.4196 0.4196 1 rgb\n/c p1\n1 setgray\n/g; #change color of both circle lines to white
 			print PSNEW;
 		}
 		close PSNEW;
 		`mv ./venn/$psnew ./venn/$psfile`;
 		$/="\n";
	}
}
