#!/usr/local/bin/perl -w

#arrange race primers in 96-well plates
# takes a tsv file as input (e.g. /projects/encode/scaling_up/whole_genome/race/primers/pooling/pools.allchr.L_5000000.l_500000.pools_65.type.compart.tsv) THAT MUST BE SORTED BY $ARGV[1]'s field
# execution example: fill_race_primer_plates.pl pools.allchr.L_5000000.l_500000.pools_65.type.compart.tsv 8
# second arg tells the program: don't fill in one given plate if current value of this field is different from the previous one, but rather start filling next plate in.
#the 96th well of each plate is left empty for positive controls
use strict;
use warnings;
use diagnostics;
use Data::Dumper;

$|=1;

die unless $ARGV[1];

my $columntogroupby=$ARGV[1]-1;
my %plate_coords=();

for (my $i=1;$i<=96;$i++){
	my $row='';
	my $col='';
	if($i<=12){
		$row='A';
		$col=$i;
	}
	elsif($i<=24){
		$row='B';
		$col=$i-12;
	}
	elsif($i<=36){
		$row='C';
		$col=$i-24;
	}
	elsif($i<=48){
		$row='D';
		$col=$i-36;
	}
	elsif($i<=60){
		$row='E';
		$col=$i-48;
	}
	elsif($i<=72){
		$row='F';
		$col=$i-60;
	}
	elsif($i<=84){
		$row='G';
		$col=$i-72;
	}
	elsif($i<=96){
		$row='H';
		$col=$i-84;
	}
	
	if($col=~/^\d$/){
		$col="0".$col;
	}
	#print "$row$col\n";
	$plate_coords{$i}=$row.$col;

}

#print Dumper \%plate_coords;

open TSV, "$ARGV[0]" or die;

my $previousgroup=' ';
my $plate=1;
my $current_well=1;
while(<TSV>){
	chomp;
	my $line=$_;
	my @line=split "\t";
	my $currentgroup=$line[$columntogroupby];
	if($_=~/^#/){
		next;
	}
	if(($previousgroup eq ' ' || $currentgroup eq $previousgroup) &&  $current_well<=94){
		print STDOUT "$line\t$plate\t$plate_coords{$current_well}\n";
		$current_well++;
		$previousgroup=$currentgroup;
	}
	else{
		$plate++;
		$current_well=1;
		print STDOUT "$line\t$plate\t$plate_coords{$current_well}\n";
		$current_well++;
		$previousgroup=$currentgroup;
	}
}
























#my %primer_line=();
#my %pool_race_groups=();
#while (<TSV>){
#	next if $_=~/^#/;
#	chomp $_;
#	my @line=split "\t";
#	$primer_line{$line[0]}=$_;
#	my $pool_race_group=$line[2]."_".$line[4];
#	push(@{$pool_race_groups{$pool_race_group}}, $line[0]);
#}


#print Dumper %pool_race_groups;

#my $plate_number=1;
#create_plate_file($plate_number);
#my $current_well=0;
#foreach my $group (sort { $a <=> $b } keys %pool_race_groups){
#	print "###################\t$group\t#####################\n";
#	if($#{$pool_race_groups{$group}}+$current_well<96){
		
#		foreach my $primer (@{$pool_race_groups{$group}}){
			
#			$current_well++;
#			print "\n$primer -> $plate_number -> $plate_coords{$current_well}\n";
#			print PLATE "$primer_line{$primer}\t$plate_coords{$current_well}\n";
#		}

#	}
#	else{
#		close PLATE;
#		print "Closing plate $plate_number. ";
#		$plate_number++;
#		print "Opening plate $plate_number.\n";
#		create_plate_file($plate_number);
#		$current_well=0;
#		foreach my $primer (@{$pool_race_groups{$group}}){
#			$current_well++;
#			print "\n$primer -> $plate_number -> $plate_coords{$current_well}\n";
#			print PLATE "$primer_line{$primer}\t$plate_coords{$current_well}\n";
#		}
#	}
#}



#sub create_plate_file{
	
#	my $inc=$_[0];
	
#	my $filename="plate_".$inc.".txt";
#	open PLATE, ">$filename" or die $!;

#}
