#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use lib "/users/rg/jlagarde/julien_utils/";
use gffToHash;
use Storable qw(dclone); 

$|=1;

##gencode sometimes contains exactly identical transcripts that differ only by the ORFs. Flux outputs only one record for those, identified by e.g. "transcript_id "ENST00000416570.1_ENST00000448975.2";".
#process flux output so that records are split (if splitting occrus then the resulting gff recoords will have the "same_as" attribute.
#example gffSplitTranscripts.pl ENCLB041ZZZGrav.bam.gencode.v16.nospikeins.flux1.5.1.gtf '_'  |sortgff > ENCLB041ZZZGrav.bam.gencode.v16.nospikeins.flux1.5.1.gtf.new





my $gffFile=shift;
my $feature_separator=shift;
my $feature_id='transcript_id';
$feature_separator=~s/("|')//g;
#print STDERR "sep= $feature_separator\n";
my %gff=gffToHash($gffFile, $feature_id);
#my %gff2=gffToHash($gffFile2, $elementAttrid);


#print Dumper \%gff;
# 
my %newGff=();
my %same_as=();
 foreach my $item (keys %gff){
  if($item=~/$feature_separator/){
    #print STDERR "item $item\n";
    my @splitFeatureId=split("$feature_separator", $item);
    #print join(" ", @splitFeatureId)."\n";
    foreach my $id (@splitFeatureId){
      #print STDERR "\%{$gff{$item}}";
      my $ref=$gff{$item};
      #print Dumper $ref;
      $newGff{$id}=dclone($gff{$item});
      @{$same_as{$id}}=@splitFeatureId;
      
      }
  }
  else{
    $newGff{$item}= dclone($gff{$item});
  }
  }
  
foreach my $id (keys %newGff){
  #print "$id\n";
  for (my $j=0; $j<=$#{$newGff{$id}};$j++){
		my @outGff=();
		my @attrs;
		for (my $i=0; $i<=7; $i++){ #processing the first 8 GFF fields
		  push(@outGff, $newGff{$id}[$j][$i]);
		}
		foreach my $key (keys %{${$newGff{$id}[$j]}[8]}){ #processing GFF attributes (9th field)
		  if($key eq $feature_id){
		    ${${$newGff{$id}[$j]}[8]}{$key}=$id;
		  }
		  push(@attrs, $key." \"${${$newGff{$id}[$j]}[8]}{$key}\";");
		}
		if(exists $same_as{$id}){
		  push (@attrs, "same_as \"".join(",", @{$same_as{$id}})."\";");
		}
		my $attr=join(" ", @attrs);
		push(@outGff, $attr);
		print join("\t", @outGff)."\n";
	}
}
