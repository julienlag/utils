#!/usr/bin/perl -w

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

	my @population=@{$columns{$col}};
	my $mean=0;
	my $numerator=0;
	#calc mean:
	foreach my $value (@population){
		$numerator+=$value;
	}
	$mean=$numerator/($#population+1);
	#calc std dev
	my $total=0;
	foreach my $value(@population){
		$total+=($mean-$value)**2;
	}
	my $mean2=$total / ($#population+1);
	my $stddev=sqrt($mean2);
	for (my $i=0; $i<=$#{$columns{$col}};$i++){
		if($stddev==0){
			${$columns{$col}}[$i]=0;
		}
		else{
			${$columns{$col}}[$i]=(${$columns{$col}}[$i] - $mean) / $stddev; #normalize each column writing Z-scores in each cell
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
