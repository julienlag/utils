#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use indexFileToHash;
use indexHashToIndexFile;
# arg 1 = index file.
# arg 2 = TSV param file specifying which lines should be affected, and in which way:
#      column 1 = patterns to search for in the index. "*" (without quotes) for all lines). 
#                 otherwise, semicolon+space-separated list of attributes e.g. "view=ExonsGencV10; lab=CSHL;", although this is not enforced by the script
#      column 2 = space-separated list of attributes to add to the lines matching the patterns in column 1.
#
die "Wrong number of args. Should be 2.\n" unless($#ARGV==1);
my $file=shift;
my $paramFile=shift;

print STDERR "
###################################
###################################

extra param file is: $paramFile

###################################
###################################
";

#my $searchPattern='';
my %extraAttrsHash=();
open PARAMS, "$paramFile" or die $!;
while (<PARAMS>){
	chomp;
	next if ($_=~/^#/);
	if($_=~/^(.*)\t(.*)$/){
		my $line=$_;
		$line=~s/;$//g;
		my @line=split("\t", $line);
		my @attrsToAdd=split("; ", $line[1]);
		#parsing first column (patterns)
		my $searchPattern=$line[0];
		#parsing second column (attributes to add)
		for (my $i=0; $i<=$#attrsToAdd;$i++){
				if($attrsToAdd[$i]=~/(\S+)=(.+)/){
					my $key=$1;
					my $value=$2;
					$extraAttrsHash{$searchPattern}{$key}=$value;
				}
				else{
					die "Malformed patterns line #$.: $_\n";
				}
			}
	}
	else{
		die "Malformed line #$.: $_\n";
	}
	
	#take "*" patterns into account
}

#print STDERR "patterns:$searchPattern\n";
my %indexFile=indexFileToHash($file);
#print STDERR Dumper \%indexFile;
#print STDERR "attrs:\n".Dumper \%extraAttrsHash;

foreach my $dataFile (sort keys %indexFile){
	#my $patternFilter=1;
#	print STDERR "$dataFile\n";
#	print STDERR "BEFORE attrs:\n".Dumper \%extraAttrsHash;
	foreach my $pattern (keys %extraAttrsHash){
#	  print STDERR "pattern1: $pattern\n";
		my $patternKey='';
		my $patternValue='';
		if($pattern eq '*'){
		  foreach my $newKey ( keys %{$extraAttrsHash{$pattern}}){
		      warn "$dataFile : attribute will be updated: $newKey->$indexFile{$dataFile}{$newKey} to $newKey->$extraAttrsHash{$pattern}{$newKey}" if (exists ($indexFile{$dataFile}{$newKey}) && ($indexFile{$dataFile}{$newKey} ne $extraAttrsHash{$pattern}{$newKey}) );
		    $indexFile{$dataFile}{$newKey}=$extraAttrsHash{$pattern}{$newKey};
		  }
		}
 		else{
#			print STDERR "pattern2: $pattern\n";
 			$pattern=~/(\S+)=(\S+);$/;
 			$patternKey=$1;
 			$patternValue=$2;
 			#test if pattern matches
 			foreach my $origKey (keys %{$indexFile{$dataFile}}){
			  if ($origKey eq $patternKey && ${$indexFile{$dataFile}}{$origKey} eq $patternValue){
			    #print STDERR "MATCH\n $dataFile $origKey = $patternKey \n ${$indexFile{$dataFile}}{$origKey} = $patternValue\n#\n";
			    foreach my $newKey (keys %{$extraAttrsHash{$pattern}}){
			      warn "$dataFile : attribute will be updated: $newKey->$indexFile{$dataFile}{$newKey} to $newKey->$extraAttrsHash{$pattern}{$newKey}" if (exists ($indexFile{$dataFile}{$newKey}) && ($indexFile{$dataFile}{$newKey} ne $extraAttrsHash{$pattern}{$newKey}) );
		    $indexFile{$dataFile}{$newKey}=$extraAttrsHash{$pattern}{$newKey};
			    }
			   
			  }
			 }
		}
#			print STDERR "AFTER attrs:\n".Dumper \%extraAttrsHash;

# 		#			foreach my $key (@{$indexFile{$dataFile}}){

# 			for (my $i=0; $i<=$#{$indexFile{$dataFile}};$i++){
# 			
# 			#here
# 				my $key=${$indexFile{$dataFile}}[$i];
# 				if ($key eq $patternKey && ${$indexFile{$dataFile}}[$i] eq $patternValue){
# 					#add or update attributes corresponding to what's in %extraAttrsHash
# 					foreach my $newKey (@{$extraAttrsHash{$pattern}}){
# 						warn "$dataFile : attribute will be updated: $key->$indexFile{$dataFile}{$key} to $key->$extraAttrsHash{$pattern}{$newKey}" if (exists ($indexFile{$dataFile}{$newKey}));
# 						$indexFile{$dataFile}{$newKey}=$extraAttrsHash{$pattern}{$newKey};
# 					}
# 				}
# 			}
# 		}
	}
#  foreach my $attr (@attrs){
#   $attr=~s/;$//g;
#   $attr=~/(\S+)=(\S+)$/;
#   my $key=$1;
#   my $value=$2;
#   $indexFile{$dataFile}{$key}=$value
#  }
#   print "$dataFile\t";
#   my @newAttrs=();
#   foreach my $key (sort keys %{$indexFile{$dataFile}}){
#    push (@newAttrs, "$key=$indexFile{$dataFile}{$key}");
#   }
#   print join("; ", @newAttrs).";\n"
 }
# 
my $outString=indexHashToIndexFile(\%indexFile);
#print STDERR Dumper \%indexFile;
print $outString;