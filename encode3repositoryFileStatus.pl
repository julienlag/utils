#!/usr/bin/perl -w

use warnings;
use Data::Dumper;
use utf8;
use JSON;
use lib "$ENV{'ENCODE3_PERLMODS'}";
use lib "/users/rg/jlagarde/julien_utils/";
use indexHashToIndexFile;
use indexFileToHash;
use Storable qw(dclone);


my $indexFile= $ARGV[0];

my %inIndexHash = indexFileToHash($indexFile);

my %outIndexHash=();

foreach my $filePath (keys %inIndexHash){
	#print STDERR "file: $filePath\n";
	if (-e $filePath){ # local file exists
		#print STDERR "$filePath exists but might not be right\n";
		my $md5file=$filePath.".md5";
		if(-e $md5file){ #local md5 sidecar file exists
			#print STDERR ".md5 file exists\n";

			my $localMd5='';
			open MD5, "$md5file" or die $!;
			while(<MD5>){
				$_=~/(\S+)  (\S+)$/;
				$localMd5=$1;
				last;
			}
			close MD5;
			$inIndexHash{$filePath}{'md5sum'}=~/"(\S+)"/;
			my $remoteMd5=$1;
			unless ($localMd5 eq $remoteMd5){
				#print STDERR "$localMd5 and $remoteMd5 md5sums don't match\n";
				%{$outIndexHash{$filePath}} = %{ dclone(\%{$inIndexHash{$filePath}})};
			}
			else{
			#print STDERR "$localMd5 and $remoteMd5 match\n";

			}
		}
		else{ #sidecar .md5 file doesn't exist
			#print STDERR ".md5 file doesn't exist\n";
			%{$outIndexHash{$filePath}} = %{ dclone(\%{$inIndexHash{$filePath}})};
		}
	}
	else{ # local file does not exist
		%{$outIndexHash{$filePath}} = %{ dclone(\%{$inIndexHash{$filePath}})};
	}

}

my $outIndexFile=indexHashToIndexFile(\%outIndexHash);
print $outIndexFile;
