#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use diagnostics;
$|=1;
#clusters ESTs believed to come from the same transcript (i.e. they share all of their intron coordinates)
#input is a BED12 file (can be gzipped)
# each hit must be uniquely identified!!

if($ARGV[0]=~/\.gz$/){
	open BED, "gzip -cd $ARGV[0]|" or die "$ARGV[0]: ".$!;
}
else{
	open BED, "$ARGV[0]" or die "$ARGV[0]: ".$!;
}

my $outPrefix=$ARGV[1];

my $verbose=$ARGV[2];

if (defined($verbose) && $verbose eq 'verbose'){
	$verbose=1;
}
elsif(defined($verbose)){
	die "Verbose flag value not understood. Possible values are 'verbose' or '' (empty string)\n";
}
else{
	$verbose=0;
}

my $clusters=$outPrefix."_clusters.tsv";
my $nr_bed=$outPrefix."_nr_clusters.bed";
#my $contig_file=$ARGV[0]."_contigs.tsv";
my %hit_total_length;
my %hit_chr;
my %hit_bed_line;
my %hit_strand;
my %hit_blockSizes;
my %hit_blockStarts;
my %hit_start;
my %hit_stop;
my %hit_score;
my $counthits=0;
print STDERR "Reading BED file...\n";
while(<BED>){
	my @line=split "\t";
	die "Need BED12 as input\n" unless ($#line==11);
	chomp $line[$#line];
	next if ($line[0]=~/^#/ || $line[0]=~/^track/);
	$counthits++;
	my $hit=$line[3];
	$hit_score{$hit}=$line[4];
	die "Duplicate ID found ($hit). Cannot continue.\n" if (exists ($hit_bed_line{$hit}));
	$hit_bed_line{$hit}=$_;
	$hit_total_length{$hit}=$line[2]-$line[1];
	$hit_chr{$hit}=$line[0];
	$hit_strand{$hit}=$line[5];

	my @blockSizes=split(",", $line[10]);
	my @blockStarts=split(",", $line[11]);
	@{$hit_blockSizes{$hit}}=@blockSizes;
	@{$hit_blockStarts{$hit}}=@blockStarts;
	$hit_start{$hit}=$line[1];
	$hit_stop{$hit}=$line[2];
}
close BED;
print STDERR "\tDone.\tRead $counthits records\n";

my %nr_cluster;
$counthits=0;
open CLUSTERS, ">$clusters" or die $!;
open NR_BED, ">$nr_bed" or die $!;
#open CONTIGS, ">$contig_file" or die $!;
#print CONTIGS "#ID\tchr(1to25)\tchrStart\tchrEnd\thitsList\n";
my $countcontigs=0;
my @keys_hit_start= sort { $hit_chr{$a} cmp $hit_chr{$b} || $hit_start{$a} <=> $hit_start{$b}} keys %hit_start;
#print STDERR "@keys_hit_start\n";
my %contig_hits=();
print STDERR "Creating contigs...\n";
my $previous_contig_end=-1;
my %contig_start;
my %contig_stop;
my %contig_chr;
for (my $i=0;$i <= $#keys_hit_start; $i++){
#foreach my $hit (sort { $hit_start{$a} <=> $hit_start{$b} } keys %hit_start){
	my $hit=$keys_hit_start[$i];
	my $contig_start= $hit_start{$hit};
	my $contig_end=$hit_stop{$hit};
	#print STDERR "hit: $hit, previous contig end: $previous_contig_end, Contig end: $contig_end, contig start: $contig_start\n";
	next if ($contig_end <= $previous_contig_end); #skip already contig-ed hits
	#print STDERR "keys hit start: $#keys_hit_start , current i: $i\n";
	$countcontigs++;
	push(@{$contig_hits{$countcontigs}}, $hit);
	#delete($hit_start_copy{$hit});

	if($i==$#keys_hit_start ){ #already in last element
		$contig_start{$countcontigs}=$contig_start;
		$contig_stop{$countcontigs}=$contig_end;
		$contig_chr{$countcontigs}=$hit_chr{$hit};
		@{$contig_hits{$countcontigs}}= sort { $hit_total_length{$b} <=> $hit_total_length{$a}  || $hit_score{$b} <=> $hit_score{$a}} @{$contig_hits{$countcontigs}};
		next;
	}
	for (my $j=$i+1; $j<= $#keys_hit_start; $j++){
		#foreach my $hit2 (sort { $hit_start_copy{$a} <=> $hit_start_copy{$b} }keys %hit_start_copy){
		my $hit2=$keys_hit_start[$j];


#	next unless ($hit_chr{$hit} == $hit_chr{$hit2});


		#print STDERR "\thit2: $hit2\n";
		#if($hit_start{$hit2} >= $hit_start{$hit} && $hit_start{$hit2}<=$hit_end{$hit}){
		if($hit_chr{$hit} eq $hit_chr{$hit2} && $hit_start{$hit2}<=$contig_end && $j<$#keys_hit_start){
			#print STDERR "\t\tfits into contig $countcontigs\n";
			push(@{$contig_hits{$countcontigs}},$hit2);
			#if ($hit_stop{$hit2} > $hit_stop{$hit}){
			if ($hit_stop{$hit2} > $contig_end){
				#print STDERR "\t\textends contig $countcontigs to $hit_stop{$hit2}\n";
				$contig_end=$hit_stop{$hit2};
			}
			#delete($hit_start_copy{$hit2});
		}
		elsif($hit_start{$hit2}<=$contig_end && $j==$#keys_hit_start ){ #end of array reached
			#print STDERR "\t\tReached last hit in array\n";
			if ($hit_stop{$hit2} > $contig_end){
				#print STDERR "\t\textends contig $countcontigs to $hit_stop{$hit2}\n";
				$contig_end=$hit_stop{$hit2};
			}
			$contig_start{$countcontigs}=$contig_start;
			$contig_stop{$countcontigs}=$contig_end;
			$contig_chr{$countcontigs}=$hit_chr{$hit};
			push(@{$contig_hits{$countcontigs}},$hit2);
			@{$contig_hits{$countcontigs}}= sort { $hit_total_length{$b} <=> $hit_total_length{$a}  || $hit_score{$b} <=> $hit_score{$a}} @{$contig_hits{$countcontigs}};
			#print STDERR "\tcontig start: $contig_start{$countcontigs}\tcontig stop: $contig_stop{$countcontigs}\n";
			$i=$j;
			#print CONTIGS "$countcontigs\t$contig_chr{$countcontigs}\t$contig_start{$countcontigs}\t$contig_stop{$countcontigs}\t".join("\t",@{$contig_hits{$countcontigs}} )."\n";
		}
		elsif($hit_chr{$hit} ne $hit_chr{$hit2}){
			#print STDERR "\t\tReached last hit on chr\n";
			$contig_start{$countcontigs}=$contig_start;
			$contig_stop{$countcontigs}=$contig_end;
			$contig_chr{$countcontigs}=$hit_chr{$hit};
			@{$contig_hits{$countcontigs}}= sort { $hit_total_length{$b} <=> $hit_total_length{$a}  || $hit_score{$b} <=> $hit_score{$a}} @{$contig_hits{$countcontigs}};
			$previous_contig_end=-1;

			$i=$j-1;
			last;
		}
		else{ #we reached the end of the contig, but some hits remain along the chr
			#print STDERR "\t\tDOESN'T fit into contig $countcontigs\n";
			$previous_contig_end=$contig_end;
			$contig_start{$countcontigs}=$contig_start;
			$contig_stop{$countcontigs}=$contig_end;
			$contig_chr{$countcontigs}=$hit_chr{$hit};
			@{$contig_hits{$countcontigs}}= sort { $hit_total_length{$b} <=> $hit_total_length{$a}  || $hit_score{$b} <=> $hit_score{$a}} @{$contig_hits{$countcontigs}};
			#print STDERR "\tcontig start: $contig_start{$countcontigs}\tcontig stop: $contig_stop{$countcontigs}\n";
			$i=$j-1;
			#print CONTIGS "$countcontigs\t$contig_chr{$countcontigs}\t$contig_start{$countcontigs}\t$contig_stop{$countcontigs}\t".join("\t",@{$contig_hits{$countcontigs}} )."\n";
			last;
		}
	}
}



#%hit_start_copy=();
print STDERR "\tDone.\t $countcontigs contigs generated.\n";
#print Dumper \%contig_hits;

print STDERR "Clustering hits...\n";
#my %contig_hits_copy= %contig_hits;

my %unclustered_hits=();
my %clustered_hits=();
#print STDERR "Contig hits: ".Dumper \%contig_hits;
#print STDERR "Contig chr: ".Dumper \%contig_chr;
foreach my $contig (keys %contig_chr){
	#print CONTIGS "$contig\t$contig_chr{$contig}\t$contig_start{$contig}\t$contig_stop{$contig}\t".join("\t",@{$contig_hits{$contig}} )."\n";
	my @keys_hits_sorted_by_startlengthscore = sort { $hit_start{$a} <=> $hit_start{$b} || $hit_total_length{$b} <=> $hit_total_length{$a} || $hit_score{$b} <=> $hit_score{$a} } @{$contig_hits{$contig}}; #sort by chrStart, then total hit length, then blat score
	verbose_print($verbose,  "contig $contig: @keys_hits_sorted_by_startlengthscore\n");
	for (my $i=0;$i<=$#keys_hits_sorted_by_startlengthscore;$i++){ #iterate over sorted hits
		my $hit=$keys_hits_sorted_by_startlengthscore[$i];
		verbose_print($verbose,  "----$hit----\n");
		$counthits++;
		if($counthits%10000==0){ print STDERR "\t$counthits hits processed\n";}

		next if (exists($clustered_hits{$hit}));
		my $cluster_name=$hit;
		push(@{$nr_cluster{$cluster_name}}, $hit);
		$unclustered_hits{$hit}=0;
		FLAG1:for(my $j=$i+1; $j<=$#keys_hits_sorted_by_startlengthscore; $j++){ #iterate over sorted hits, starting at $i+1
			my $hit2=$keys_hits_sorted_by_startlengthscore[$j];
			#my $first_exon_match=0; #boolean: 0 if first exon match between hit and hit2 still to be found, 1 if already found
			verbose_print($verbose,  "$hit vs. $hit2\n");

			if ($hit_strand{$hit} eq $hit_strand{$hit2}){ #we don't check for chr_hit == chr_hit2 as they are already contigued, hence on the same one for sure
				verbose_print($verbose,  "\t$hit_start{$hit2} $hit_start{$hit} || $hit_stop{$hit2} $hit_stop{$hit}\n");
				#next if ($hit_start{$hit2}<$hit_start{$hit} || $hit_stop{$hit2}>$hit_stop{$hit});
				next if($hit_stop{$hit2}>$hit_stop{$hit}); #i.e. hit2 starts after hit starts, but also stops after hit stops, i.e. they can't be in the same cluster -> we skip this hit2
				my $l=0; # to iterate over hit exons
				for(my $k=0;$k<=$#{$hit_blockStarts{$hit2}};$k++){
# iterate over hit2 exons
# we start at the *FIRST* blockStart, i.e. *START* of the first intron, and stop at the *PENULTIMATE*
					my $hit2_exonstart=${$hit_blockStarts{$hit2}}[$k];
					my $hit2_exonstop=${$hit_blockStarts{$hit2}}[$k]+${$hit_blockSizes{$hit2}}[$k];
					verbose_print($verbose,  "\tHit2 exon: $hit2_exonstart $hit2_exonstop\n");
					for( $l=$l;$l<=$#{$hit_blockStarts{$hit}};$l++){
#iterate over hit exons
# we start at the *FIRST* blockStart, i.e. *START* of the first intron, and stop at the *PENULTIMATE*
						my $hit_exonstart=${$hit_blockStarts{$hit}}[$l];
						my $hit_exonstop=${$hit_blockStarts{$hit}}[$l]+${$hit_blockSizes{$hit}}[$l];

						verbose_print($verbose,  "\t\tHit exon: $hit_exonstart $hit_exonstop\n");

						if($k==0){ #first exon of hit2
							verbose_print($verbose,  "\t\tfirst exon of hit2\n");
							if($hit2_exonstart>$hit_exonstop){ #maybe the 1st exon of hit2 is not incl. in the 1st of hit, if so we just skip it and check the next 'hit' one
								$unclustered_hits{$hit2}=1 unless(exists $unclustered_hits{$hit2});
								verbose_print($verbose,  "\t\t\t$hit2_exonstart>$hit_exonstop, go to next hitExon\n");
								next;
							}
							elsif($hit2_exonstart>=$hit_exonstart){
								verbose_print($verbose,  "\t\t\t$hit2_exonstart>=$hit_exonstart:\n");
								if($k==$#{$hit_blockStarts{$hit2}}){ # hit2 is unspliced, then hit2stop doesn't need to be == hitstop but can be <
									verbose_print($verbose,  "\t\t\t\t$hit2 unspliced\n");
									if($hit2_exonstop<=$hit_exonstop){
										verbose_print($verbose,  "\t\t\t\t\t$hit2 FITS INTO $hit\n");
										push(@{$nr_cluster{$hit}}, $hit2);
										$clustered_hits{$hit2}=1;
										$unclustered_hits{$hit2}=0;
									}
									else{
										verbose_print($verbose,  "\t\t\t\t\t$hit2 DOESN'T FIT INTO $hit, skip to next hit2\n");
										$unclustered_hits{$hit2}=1 unless(exists $unclustered_hits{$hit2});
									}
								}
								else{
									verbose_print($verbose,  "\t\t\t\t$hit2 looks spliced\n");
									if($hit2_exonstop==$hit_exonstop){
										verbose_print($verbose,  "\t\t\t\t\t$hit2_exonstop==$hit_exonstop, moving to next exon of $hit2\n");
										$unclustered_hits{$hit2}=1 unless(exists $unclustered_hits{$hit2});
										$l++;
										last;
									}
									else{
										verbose_print($verbose,  "\t\t\t\t\t$hit2_exonstop==$hit_exonstop, moving to next hit2\n");
										$unclustered_hits{$hit2}=1 unless(exists $unclustered_hits{$hit2});
										next FLAG1;
									}
								}
							}
							else{
								verbose_print($verbose,  "\t\t\t$hit2_exonstart<$hit_exonstart, hence $hit2 DOESN'T FIT INTO $hit, skip to next hit2\n");
								$unclustered_hits{$hit2}=1 unless(exists $unclustered_hits{$hit2});
								next FLAG1;
							}
						}

						elsif($k==$#{$hit_blockStarts{$hit2}}){ #last exon of hit2
							verbose_print($verbose,  "\t\tReached last exon of hit2\n");
							if($hit2_exonstart==$hit_exonstart && $hit2_exonstop<=$hit_exonstop){
								verbose_print($verbose,  "\t\t\t($hit2_exonstart==$hit_exonstart && $hit2_exonstop<=$hit_exonstop), hence $hit2 FITS INTO $hit\n");
								push(@{$nr_cluster{$hit}}, $hit2);
								$clustered_hits{$hit2}=1;
								$unclustered_hits{$hit2}=0;
								last;
							}
							else{
								verbose_print($verbose,  "\t\t\t!($hit2_exonstart==$hit_exonstart && $hit2_exonstop<=$hit_exonstop), hence $hit2 DOESN'T FIT INTO $hit, skip to next hit2\n");
								$unclustered_hits{$hit2}=1 unless(exists $unclustered_hits{$hit2});
								next FLAG1;
							}
						}
						else{ #internal exon of hit2
							verbose_print($verbose,  "\t\tInternal exon of hit2\n");
							if($hit2_exonstart == $hit_exonstart && $hit2_exonstop == $hit_exonstop){ #internal exon ok
								verbose_print($verbose,  "\t\tInternal exon ok\n");
								$l++;
								last;
							}
							else{
								verbose_print($verbose,  "\t\tInternal exon NOT OK, moving to next hit2\n");
								$unclustered_hits{$hit2}=1 unless(exists $unclustered_hits{$hit2});
								next FLAG1;
							}

						}
					}
				}
			}
		}
	}
}








foreach my $hit (keys %unclustered_hits){ #remaining hits, i.e. clusters of size 1
	if($unclustered_hits{$hit}==1){
		verbose_print($verbose, "$hit unclustered\n");
		push(@{$nr_cluster{$hit}}, $hit);
	}
}


foreach my $cluster (keys %nr_cluster){
	my @sortedHitIDs=sort (@{$nr_cluster{$cluster}});
	print CLUSTERS "$cluster\t".join (",", @sortedHitIDs)."\n";
	print NR_BED $hit_bed_line{$cluster};
}
print STDERR "Merging done\n";





sub verbose_print{


	if($_[0] ==1){ print STDERR $_[1];}
}
