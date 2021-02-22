#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
$|=1;
my $key_to_sort_on='replicate';
#$key_to_sort_on = $ARGV[0] if ($ARGV[0]);

while(<>){
	my $line=$_;
	#print "OLD: $line";
	chomp;
	$_=~s/\s+$//g;
	my @line=split "\t";
	my @attrs=split (";", $line[1]);
	my %attrHash=();
	foreach my $keyvalue (@attrs){
		#print STDERR "'$keyvalue'\n";
		$keyvalue=~s/^\s+//;
		#print STDERR "$keyvalue\n";
		$keyvalue=~/^(\S+)=(.+)$/;
		my $key=$1;
		my $value=$2;
		@{$attrHash{$key}}=split(",",$value);
		if($#{$attrHash{$key}}>1){
			warn "Line not processed: more than 2 elements in list $1 at line $.:\n $line";
			print $line;
		}
		
	}
	unless (exists ($attrHash{$key_to_sort_on})){
		warn "Line not processed: key $key_to_sort_on absent  at line $.:\n $line";
		print "$line";
	}
	elsif($#{$attrHash{$key_to_sort_on}}<1){
		print "$line";
	}

	elsif((${$attrHash{$key_to_sort_on}}[1] cmp ${$attrHash{$key_to_sort_on}}[0]) < 1){ #badly ordered
		print STDERR "BAD ORDER ${$attrHash{$key_to_sort_on}}[1] cmp ${$attrHash{$key_to_sort_on}}[0], reversing it.\n";
		#print STDERR "BEFORE".Dumper \%attrHash;

		foreach my $key (keys %attrHash){ #reverse array
			#print "$key\t$#{$attrHash{$key}}\t@{$attrHash{$key}}\n";
			if($#{$attrHash{$key}}>0 && $key ne "labVersion"){
				my @tmp=@{$attrHash{$key}};
				my @tmpRev = reverse (@tmp);
				#print "@tmp .\t. @tmpRev\n";
				@{$attrHash{$key}}=@tmpRev;
			}
		}
			#print STDERR "REVERSED\n";
		print "$line[0]\t";
		my @newAttrs=();
		foreach my $key (keys %attrHash){
			push (@newAttrs, "$key=".join(",",@{$attrHash{$key}}));
		}
		print join("; ", @newAttrs)."\n";
	}
	else{
		print "$line";
	}
	
	#print Dumper \@attrs;
	#print STDERR "AFTER".Dumper \%attrHash;
}
