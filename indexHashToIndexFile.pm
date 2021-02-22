use strict;
use warnings;
use Data::Dumper;


sub indexHashToIndexFile{
  my $indexHashRef=$_[0];
  my %indexHash=%$indexHashRef;
    #print Dumper \%indexHash;
  #my %indexFile=indexFileToHash($file);
  my $outIndexString='';
   foreach my $filePath (sort keys %indexHash){
    $filePath=~/(\S+)/; #remove any space
 	my $outLine="$1\t";
 	foreach my $attr (sort keys %{$indexHash{$filePath}}){
    if(defined $indexHash{$filePath}{$attr}){
      unless($indexHash{$filePath}{$attr}=~/^".+"$/){
        $indexHash{$filePath}{$attr}="\"$indexHash{$filePath}{$attr}\"";
      }
      $indexHash{$filePath}{$attr}=~s/(\r)|(\n)|(\t)|(;)//g;
	  $outLine.="$attr=$indexHash{$filePath}{$attr}; ";
  }
 	}
 	$outLine=~s/ $//; #remove trailing space
 	$outLine.="\n";
 	$outIndexString.=$outLine;
   }
   return $outIndexString;
  }

1;