#!/usr/bin/perl -w
use strict;
use warnings;

print "<table border=\"1\">\n";

while(<>){
	chomp;
	my @line=split "\t";
	print "<tr>\n";
	if($.==1){ #1st line = table header
		foreach my $i (@line){
			print "<th>$i</th>\n";
		}
	}
	else{
		foreach my $i (@line){
			print "<td>$i</td>\n";
		}
	}
	print "</tr>\n";
}

print "</table>\n";
