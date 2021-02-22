#!/usr/local/bin/perl -w



use strict;
use warnings;


open F, "$ARGV[0]" or die $!;

while(<F>){
	next unless($_=~/^chr/);
	my @line=split "\t";
	
	#if ($line[3]=~/\w+\|^(\|)+\|\w+\|(\|)+\|/){
	#print STDERR "'$line[3]'\n";
	if ($line[3]=~/\w+\|\S+\|\w+\|(\S+)\|/){	
		$line[3]=$1;
	}
	else{
		print STDERR "ERROR $line[3]";
	}
	print STDOUT join("\t",@line);

} 
