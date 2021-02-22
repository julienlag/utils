#!/usr/bin/perl -w
use lib "/users/rg/jlagarde/julien_utils/";
use encode_metadata; 
#1st arg = metadata file e.g. /users/rg/jlagarde/projects/encode/scaling/whole_genome/dcc_submission/samples/all_Gingeras_Mouse_samples.tsv
#2nd arg = organism (mouse or human)
#3rd arg =input index file
my %labExpId2metadata=encode_metadata::encode_metadata("$ARGV[0]",0,"$ARGV[1]");
open F, "$ARGV[2]", or die $!;
while(<F>){
	#print;
	chomp;
	my $line=$_;
   	if($_=~/replicate=/){
		print "$line\n";
	}
	elsif($_=~/labExpId=(\S+);/){
		
	#	my $line=$_;
		print STDERR "$1\n";
		my @labExpIds=split(",",$1);
		my @reps=();
		foreach my $l (@labExpIds){
			print STDERR "$l $labExpId2metadata{$l}{'replicate'}\n";
			push(@reps, $labExpId2metadata{$l}{'replicate'});
		}
		print $line."; replicate=".join(",",@reps)."\n";
	}
	else{
		warn "No replicate found, no labExpId found. Skipped. Offending line is:\n$line\n";
		print "$line\n";
	}
}
