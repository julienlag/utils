#!/usr/local/bin/perl -w

use strict; 
use warnings; 
use Data::Dumper; 

my %columns=(); 
my %col_min=();
my %col_max=();
my $col_number=0;
my $line_number=0;
while (<>){
	chomp; 
	
	my @line=split "\t"; 
	$line_number++;
	$col_number=$#line;
	for(my $i=0; $i<=$#line;$i++){
		push(@{$columns{$i}}, $line[$i]);
	}
}

foreach my $col (sort {$a <=> $b} keys %columns){
	$col_min{$col}=10000000000000000000000000000000000000000000000000000000000;
	$col_max{$col}=-10000000000000000000000000000000000000000000000000000000000;
	for my $val (@{$columns{$col}}){
		if($val>$col_max{$col}){
			$col_max{$col}=$val;
		}
		if($val<$col_min{$col}){
			$col_min{$col}=$val;
		}
	}

}

foreach my $col (sort {$a <=> $b} keys %columns){
	for (my $i=0; $i<=$#{$columns{$col}};$i++){
		unless($col_max{$col}-$col_min{$col}==0){
			${$columns{$col}}[$i]=(${$columns{$col}}[$i]-$col_min{$col})/($col_max{$col}-$col_min{$col}); #normalize each column
		}
	}
}


#print Dumper \%columns;
#print $line_number;

for (my $i=0; $i<$line_number;$i++){
	for(my $j=0;$j<=$col_number;$j++){
		
		print "${$columns{$j}}[$i]\t";
	}
	print "\n";
}
