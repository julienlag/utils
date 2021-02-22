#!/usr/local/bin/perl -w

use strict;
use warnings;
use Data::Dumper;
use diagnostics;
#use Readonly;
$|=1;

#merges long introns that are missed by blat, e.g.:
#744     0       0       0       0       0       0       0       +       chr21_43196342_43197102_MX2     986     242     986     chr21   46944323        431,       242,    43196358,
#243     0       0       0       0       0       0       0       +       chr21_43196342_43197102_MX2     986     0       243     chr21   46944323        417,       0,      41701787,

#WARNING: "CHAINED" SPLICE JUNCTIONS ARE APPROXIMATE AND SHOULD BE CHECKED MANUALLY



open CHAINANCHORED, "$ARGV[0]" or die "$ARGV[0]: ".$!;
open ALL, "$ARGV[1]" or die "$ARGV[1]: ".$!;
my %pslIndex=();
my $autoIncIndex=0;
my %queryseq_chr_qStart_qEnd_tStart_tEnd_line=();
#my $lastIndex=0;
my $counthits=0;
my $countperfecthits=0;
while(<CHAINANCHORED>){
	$counthits++;
	chomp;
	my @line=split "\t";
	my $pslline=$_;
	unless($line[0]=~/^\d+$/){ #skips header
		next;
	}
	if (($line[0]+$line[1]+$line[2])/$line[10] == 1){ #skips and directly prints hits where the seq is 100% covered by alignment
		#print STDOUT $pslline."\n";
		$countperfecthits++;
		next;
	}
	$autoIncIndex++;
	#$lastIndex++;
	@{$pslIndex{$autoIncIndex}}=@line;
	if(exists $queryseq_chr_qStart_qEnd_tStart_tEnd_line{$line[9]}{$line[13]}{$line[11]}{$line[12]}{$line[15]}{$line[16]}){
		die "$pslline\n";
	}
	
	$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$line[9]}{$line[13]}{$line[11]}{$line[12]}{$line[15]}{$line[16]}=$autoIncIndex;
}

my %queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits=();
while (<ALL>){
	chomp;
	my @line=split "\t";
	my $pslline=$_;
	unless($line[0]=~/^\d+$/){ #skips header
		next;
	}
	if (($line[0]+$line[1]+$line[2])/$line[10] == 1){ #skips and directly prints hits where the seq is 100% covered by alignment
		#print STDOUT $pslline."\n";
		next;
	}
	$autoIncIndex++;
	#$lastIndex++;
	@{$pslIndex{$autoIncIndex}}=@line;
	if(exists $queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits{$line[9]}{$line[13]}{$line[11]}{$line[12]}{$line[15]}{$line[16]}){
		die "$pslline\n";
	}
	
	$queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits{$line[9]}{$line[13]}{$line[11]}{$line[12]}{$line[15]}{$line[16]}=$autoIncIndex;

}


#print STDERR Dumper \%queryseq_chr_line;

#my %pslIndex2 = %pslIndex;
my $countchains=0;
my $counthitsinchains=0;
my $counthitsnotinchains=0;
my %currPslIndex=();
foreach my $queryseq (keys %queryseq_chr_qStart_qEnd_tStart_tEnd_line){
	#print STDERR "\n$queryseq\t";
	foreach my $chr (keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}}){
		#print STDERR "$chr\t";
		#my @qStarts=();
		#my @qEnds=();
		#my $previous_qEnd=0;
		my $second_index=0;
		my %chain=();
		my $chain_bool=0;
		my %tochain=();
		foreach my $qStart (sort {$a <=> $b} keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}} ){
			#$chain_bool=0;
			#print STDERR "qStart: $qStart\t";
			foreach my $qEnd (sort {$b <=> $a} keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}} ){
				#$previous_qEnd=$qEnd;
#				print STDERR "qEnd: $qEnd\t";
				
				foreach my $tStart (sort {$a <=> $b} keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}} ){
#					print STDERR "tStart: $tStart\t";
					foreach my $tEnd (keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}{$tStart}}){
						print STDOUT "$queryseq\t${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}{$tStart}{$tEnd}}}[10]\t$qStart..$qEnd\t$chr\t${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}{$tStart}{$tEnd}}}[8]\t$tStart\t${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}{$tStart}{$tEnd}}}[16]\t${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}{$tStart}{$tEnd}}}[17]\ta\n";
						foreach my $chr2 (keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits{$queryseq}}){
							foreach my $qStart2 (sort {$a <=> $b} keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits{$queryseq}{$chr2}} ){
								unless ($qStart2 == $qStart){
									
									foreach my $qEnd2 (sort {$b <=> $a} keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits{$queryseq}{$chr2}{$qStart2}} ){
										if(($qStart2>$qEnd-10 && $qStart2<$qEnd+10) ||($qEnd2>$qStart -10 && $qEnd2<$qStart+10 )){

											foreach my $tStart2 (sort {$a <=> $b}  keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits{$queryseq}{$chr2}{$qStart2}{$qEnd2}} ){
												foreach my $tEnd2 (keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits{$queryseq}{$chr2}{$qStart2}{$qEnd2}{$tStart2}}){
													
													print STDOUT "$queryseq\t${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits{$queryseq}{$chr2}{$qStart2}{$qEnd2}{$tStart2}{$tEnd2}}}[10]\t";
													print STDOUT "$qStart2..$qEnd2\t$chr2\t${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits{$queryseq}{$chr2}{$qStart2}{$qEnd2}{$tStart2}{$tEnd2}}}[8]\t";
													print STDOUT "$tStart2\t${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits{$queryseq}{$chr2}{$qStart2}{$qEnd2}{$tStart2}{$tEnd2}}}[16]\t";
													print STDOUT "${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line_allhits{$queryseq}{$chr2}{$qStart2}{$qEnd2}{$tStart2}{$tEnd2}}}[17]\n";
													}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
#					foreach my $second_qStart(sort {$a <=> $b} keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}}){
#						print STDERR "second_qStart: $second_qStart\t";
#						if($second_qStart>$qEnd-10 && $second_qStart<$qEnd+10){
#						#if($second_qStart==$qEnd){
#
#							foreach my $second_qEnd (sort {$b <=> $a} keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$second_qStart}} ){
#								foreach my $second_tStart (sort {$a <=> $b}  keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$second_qStart}{$second_qEnd}} ){
#									if((($second_tStart<$tStart && ${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$second_qStart}{$second_qEnd}{$second_tStart}}}[8] eq '-') || ($second_tStart>$tStart && ${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$second_qStart}{$second_qEnd}{$second_tStart}}}[8] eq '+')) && (${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$second_qStart}{$second_qEnd}{$second_tStart}}}[8] eq ${$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}{$tStart}}}[8])){
#										$second_index=$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$second_qStart}{$second_qEnd}{$second_tStart};
#										#if(($previous_qEnd>0) && ($qStart>$previous_qEnd-10 && $qStart<$previous_qEnd+10)){
#										$chain{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}{$tStart}}=$second_index;
#										$tochain{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}{$tStart}}=1;
#										$tochain{$second_index}=1;
#										$chain_bool=1;
#										#print STDERR "\n\nCHAIN: $chr, $qStart, $qEnd, $tStart with $second_qStart, $second_qEnd, $second_tStart\n\n";
#										last; #stops at first instance
#									}
#								}
#							}
#							last;
#						}
#						#else{
#							#print STDOUT join("\t",@{$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}{$tStart}}})."\n";	
#							print STDERR "NO\t";
#						#}
#						
#					}
#					
#					last; #stops at first instance
#				}
#			}
#		}
		#print STDERR "Chain graph hash: ".Dumper \%chain;
#		if($chain_bool==1){ #putative chain(s) found on chr
			#print STDOUT "\n\nWill chain $queryseq on $chr:\n\n";
#			my %chain_index=();
#			my $increment=0;
#			foreach my $id (keys %chain){
#				push(@{$chain_index{$increment}},$id,$chain{$id});
#				if (!exists $chain{$chain{$id}}){ #verify that the graph is not connex (i.e. we're at the end of the chain)
#					my $found=0;
#					foreach my $value (values %chain){
#						if($value==$id){
#							$found=1;
#							last;
#						}
#					}
#					if($found==0){
#						$increment++;
#					}
#				}
#				#push(@chain_index, $id,$chain{$id});
#			}
#			#print STDERR Dumper \%chain_index;
#			foreach my $chain (keys %chain_index){
#				#print STDERR "Chain: $chain\n";
#				my %seen = ();
#				my @uniq;
#				foreach my $item (@{$chain_index{$chain}}) {
#					push(@uniq, $item) unless $seen{$item}++;
#				}
#				@{$chain_index{$chain}}=@uniq;
				#$lastIndex++;
				#print STDERR "BEFORE loop: ".Dumper \@{$chain_index{$chain}};
#				$counthitsinchains=$counthitsinchains+$#{$chain_index{$chain}}+1;
				#%currPslIndex=%pslIndex;
				#print STDERR "currPslIndex BEFORE pop.:\n".Dumper \%currPslIndex;
				
#				for (my $i=0;$i<=$#{$chain_index{$chain}};$i++){
					#print STDERR "in pslIndex:\n ${$chain_index{$chain}}[$i] -> ".join("\t",@{$pslIndex{${$chain_index{$chain}}[$i]}})."\n";
#					@{$currPslIndex{${$chain_index{$chain}}[$i]}}=@{$pslIndex{${$chain_index{$chain}}[$i]}};

#				}
				#print STDERR "currPslIndex AFTER pop.:\n".Dumper \%currPslIndex;
#				for (my $i=0;$i<$#{$chain_index{$chain}};$i++){
					#print STDERR "currPslIndex_chain_index_chain_i+1: $currPslIndex{${$chain_index{$chain}}[$i+1]}\n";
					#print STDERR "\nlast BEFORE:\n".join("\t",@{$currPslIndex{${$chain_index{$chain}}[$#{$chain_index{$chain}}]}})."\n";
					#print STDERR "\ncurrent BEFORE:\n".join("\t",@{$currPslIndex{${$chain_index{$chain}}[$i]}})."\n";
					#print STDERR "in pslIndex before:\n ${$chain_index{$chain}}[$i] (current)-> ".join("\t",@{$pslIndex{${$chain_index{$chain}}[$i]}})."\n";
					#print STDERR "in pslIndex before:\n ${$chain_index{$chain}}[$i+1] (next)-> ".join("\t",@{$pslIndex{${$chain_index{$chain}}[$i+1]}})."\n";
#					my @tmp=();
#					@tmp=chain_psl_lines(${$chain_index{$chain}}[$i],${$chain_index{$chain}}[$i+1]);
					#print STDERR "in pslIndex after:\n ${$chain_index{$chain}}[$i] -> ".join("\t",@{$pslIndex{${$chain_index{$chain}}[$i]}})."\n";
					#print STDERR "in pslIndex after:\n ${$chain_index{$chain}}[$i+1] (next)-> ".join("\t",@{$pslIndex{${$chain_index{$chain}}[$i+1]}})."\n";
#					@{$currPslIndex{${$chain_index{$chain}}[$i+1]}}=@tmp;
					#print STDERR "in pslIndex after tmp:\n ${$chain_index{$chain}}[$i] -> ".join("\t",@{$pslIndex{${$chain_index{$chain}}[$i]}})."\n";
					#print STDERR "in pslIndex after tmp:\n ${$chain_index{$chain}}[$i+1] (next)-> ".join("\t",@{$pslIndex{${$chain_index{$chain}}[$i+1]}})."\n";
					#print STDERR "\nlast AFTER:\n".join("\t",@{$currPslIndex{${$chain_index{$chain}}[$#{$chain_index{$chain}}]}})."\n";
#				}
				#print STDERR "AFTER loop: ".Dumper \@{$chain_index{$chain}};
#				$countchains++;
#				print STDOUT join("\t",@{$currPslIndex{${$chain_index{$chain}}[$#{$chain_index{$chain}}]}})."\n";
#			}
#		}
		#else{
#		foreach my $qStart (keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}} ){
#			foreach my $qEnd (keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}} ){
#				foreach my $tStart (keys %{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}} ){
#					unless (exists ($tochain{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}{$tStart}})){
#						$counthitsnotinchains++;
#						print STDOUT join("\t",@{$pslIndex{$queryseq_chr_qStart_qEnd_tStart_tEnd_line{$queryseq}{$chr}{$qStart}{$qEnd}{$tStart}}})."\n";
#					}	
#				}
#			}
			#}
#		}
#	}
#}
#print STDERR "\n$counthits hits in input PSL in total.\n";
#my $countimperfecthits=$counthits-$countperfecthits;
#print STDERR "\t$countperfecthits perfect 100% coverage hits in input PSL (i.e. $countimperfecthits imperfect hits possibly to chain).\n";
#print STDERR "\t$counthitsnotinchains imperfect hits could not be chained.\n";
#print STDERR "\t$countchains new chains generated out of $counthitsinchains hits.\n";
#my $totalinoutput=$counthitsinchains+$counthitsnotinchains+$countperfecthits;
#print STDERR "Total (=$counthits? but not necessarily: one hit can be included in several chains): $counthitsinchains+$counthitsnotinchains+$countperfecthits=$totalinoutput\n";


sub chain_psl_lines{
	my $first_id;
	my $second_id;
	if(${$currPslIndex{$_[0]}}[11]<${$currPslIndex{$_[1]}}[11]){
		$first_id=$_[0]; #256
		$second_id=$_[1]; #266
	}
	else{
		$first_id=$_[1];
		$second_id=$_[0];
	}
	#print STDERR "1: $first_id ".join("\t",@{$pslIndex{$first_id}})."\n";
	#print STDERR "1: $second_id ".join("\t",@{$pslIndex{$second_id}})."\n";
	
	#my $newIndex=$_[2];
	my @psl=();
	#print STDOUT join("\t",@{$currPslIndex{$first_id}})."\n";
	
	$psl[0]=${$currPslIndex{$first_id}}[0]+${$currPslIndex{$second_id}}[0];
	$psl[1]=${$currPslIndex{$first_id}}[1]+${$currPslIndex{$second_id}}[1];
	$psl[2]=${$currPslIndex{$first_id}}[2]+${$currPslIndex{$second_id}}[2];
	$psl[3]=${$currPslIndex{$first_id}}[3]+${$currPslIndex{$second_id}}[3];
	$psl[4]=${$currPslIndex{$first_id}}[4]+${$currPslIndex{$second_id}}[4];
	$psl[5]=${$currPslIndex{$first_id}}[5]+${$currPslIndex{$second_id}}[5];
	$psl[6]=${$currPslIndex{$first_id}}[6]+${$currPslIndex{$second_id}}[6];
	$psl[7]=${$currPslIndex{$first_id}}[7]+${$currPslIndex{$second_id}}[7];
	#print STDERR "2: $first_id ".join("\t",@{$pslIndex{$first_id}})."\n";
	#print STDERR "2: $second_id ".join("\t",@{$pslIndex{$second_id}})."\n";
	
	unless(${$currPslIndex{$first_id}}[8] eq ${$currPslIndex{$second_id}}[8]){
		
		print STDERR "WARNING: Attempted chaining of 2 exons on different strands in seq ${$currPslIndex{$first_id}}[9] on ${$currPslIndex{$first_id}}[13]. This will NOT be reflected in the output chained PSL.\n";
		return @{$currPslIndex{$_[1]}};
	}
	#print STDERR "3: $first_id ".join("\t",@{$pslIndex{$first_id}})."\n";
	#print STDERR "3: $second_id ".join("\t",@{$pslIndex{$second_id}})."\n";
	
	$psl[8]=${$currPslIndex{$first_id}}[8];
	#print STDERR "4: $first_id ".join("\t",@{$pslIndex{$first_id}})."\n";
	#print STDERR "4: $second_id ".join("\t",@{$pslIndex{$second_id}})."\n";
	
	die "Tried to chain 2 exons from different transcripts. This is a bug.\n" if (${$currPslIndex{$first_id}}[9] ne ${$currPslIndex{$second_id}}[9]);
	$psl[9]=${$currPslIndex{$first_id}}[9];
	$psl[10]=${$currPslIndex{$first_id}}[10];
	$psl[11]=${$currPslIndex{$first_id}}[11];
	$psl[12]=${$currPslIndex{$second_id}}[12];
	#print STDERR "5: $first_id ".join("\t",@{$pslIndex{$first_id}})."\n";
	#print STDERR "5: $second_id ".join("\t",@{$pslIndex{$second_id}})."\n";
	
	die "Tried to chain 2 exons on different chromosomes. This is a bug.\n" if (${$currPslIndex{$first_id}}[13] ne ${$currPslIndex{$second_id}}[13]);
	$psl[13]=${$currPslIndex{$first_id}}[13];
	$psl[14]=${$currPslIndex{$first_id}}[14];
	#print STDERR "6: $first_id ".join("\t",@{$pslIndex{$first_id}})."\n";
	#print STDERR "6: $second_id ".join("\t",@{$pslIndex{$second_id}})."\n";
	
	if(${$currPslIndex{$first_id}}[8] eq '+'){
		$psl[15]=${$currPslIndex{$first_id}}[15];
		$psl[16]=${$currPslIndex{$second_id}}[16];
		$psl[18]=${$currPslIndex{$first_id}}[18].${$currPslIndex{$second_id}}[18];
		$psl[19]=${$currPslIndex{$first_id}}[19].${$currPslIndex{$second_id}}[19];
		$psl[20]=${$currPslIndex{$first_id}}[20].${$currPslIndex{$second_id}}[20];
		#print STDERR "7: $first_id ".join("\t",@{$pslIndex{$first_id}})."\n";
		#print STDERR "7: $second_id ".join("\t",@{$pslIndex{$second_id}})."\n";
	}
	elsif(${$currPslIndex{$first_id}}[8] eq '-'){
		$psl[15]=${$currPslIndex{$second_id}}[15];#266->
			$psl[16]=${$currPslIndex{$first_id}}[16];#256->
			$psl[18]=${$currPslIndex{$second_id}}[18].${$currPslIndex{$first_id}}[18];
		$psl[19]=${$currPslIndex{$second_id}}[19].${$currPslIndex{$first_id}}[19];
		$psl[20]=${$currPslIndex{$second_id}}[20].${$currPslIndex{$first_id}}[20];
		#print STDERR "7: $first_id ".join("\t",@{$pslIndex{$first_id}})."\n";
		#print STDERR "7: $second_id ".join("\t",@{$pslIndex{$second_id}})."\n";
	}
	#print STDERR "7: ".join("\t",@{$pslIndex{$first_id}})."\n";
	#print STDERR "7: ".join("\t",@{$pslIndex{$second_id}})."\n";
	#print STDERR "8: ".join("\t",@{$pslIndex{$first_id}})."\n";
	#print STDERR "8: ".join("\t",@{$pslIndex{$second_id}})."\n";
	
	else{
		die;
	}
	$psl[17]=${$currPslIndex{$first_id}}[17]+${$currPslIndex{$second_id}}[17];
	#$psl[19]=${$currPslIndex{$first_id}}[19].${$currPslIndex{$second_id}}[19];
	#print STDERR "8: $first_id ".join("\t",@{$pslIndex{$first_id}})."\n";
	#print STDERR "8: $second_id ".join("\t",@{$pslIndex{$second_id}})."\n";
	
	return @psl;
	#${$currPslIndex{$newIndex}}[14]=
	
}
