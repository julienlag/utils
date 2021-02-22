#!/usr/bin/env perl

@keys=@ARGV;
#print STDERR "@keys\n";

while(<STDIN>){
	@line=split "\t";
	@out=();
	foreach $key (@keys){

		if($line[1]=~/$key="(.+?)";*/ ){
			push(@out,$1);
		}
		else{
			warn "key $key not found:\n$_"
		}
	}
	if($#out>=0){
		print join("\t", @out)."\n";
	}
}
