#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use DBI;

$|=1;
die "Wrong number of arguments (should be 5).\n" unless ($#ARGV==4);
my $local_prefix=$ARGV[0];
my $ddf=$ARGV[1];
my $extrageneralparameters=$ARGV[2];
my $copyFilesOver=$ARGV[3]; # 0 = do not copy any file to $local_prefix; 1 =  copy files to $local_prefix
my $dataDir=$ARGV[4];
die "Wrong value for 4th arg. Should be 0 (do not copy any file to $local_prefix) or 1 (copy files to $local_prefix)\n" unless ($copyFilesOver == 0 || $copyFilesOver == 1);
my $url_prefix=$local_prefix;
$url_prefix=~s/\/users\/rg\/jlagarde\/public_html/http:\/\/genome\.crg\.es\/~jlagarde\//g;


open DDF, "$ddf" or die $!;
my @generalkeys=();
my @generalvalues=();
if($extrageneralparameters){
	open PARAMS, "$extrageneralparameters" or die $!;
	while (<PARAMS>){
		chomp;
		if($.==1){
			@generalkeys=split "\t";
		}
		else{
			@generalvalues=split "\t";
			die '@generalvalues and @generalkeys don\'t have the same number of elements\n' unless ($#generalkeys == $#generalvalues); 
		}
		
	}
	close PARAMS;
}
my @keys=();
while(<DDF>){
	#print;
	my $line=$_;
#	$line = $1 if ($line=~/(.+)\s+$/);
#	$line=~s/\t(\s)/\t\.$1/g;
	#print STDERR $line;
	chomp $line;
	if($.==1){
		@keys=split ("\t", $line, -1);
		push(@keys, @generalkeys);
	}
	else{
		#print "@keys\n";
		my $fileType='';
		my @values=split ("\t", $line, -1);
		push(@values, @generalvalues);
		#print STDERR "@values\n@keys\n";
		#print STDERR "$#values\n$#keys\n";
		die '@values and @keys don\'t have the same number of elements'."\n@values\n@keys\n" unless ($#keys == $#values); 
		my %seen_keys=();
		for (my $i=0; $i<=$#keys; $i++){
			#print STDERR "'$keys[$i]' '$values[$i]'\n";
			if (exists $seen_keys{$keys[$i]}){
				warn "Duplicate key $keys[$i] found for line:\n$line\nOnly $seen_keys{$keys[$i]} is kept.\n";
				next;
			}
			$seen_keys{$keys[$i]}=$values[$i];
			if($keys[$i] eq 'files') {
				$values[$i]=~/\S+\.(\S+)$/;
				$fileType=$1;
				unless($values[$i] =~ /,/){ # if list of files (e.g. if one FASTQ entry is split into one file per lane), links cannot be made.
					if($values[$i]=~/\S+\.txt\.gz$/){
						$fileType="fastq";
					}
					my @tmp=split ("/", $values[$i]);
					my $targetFilename=$tmp[$#tmp];
					#print "$url_prefix/$values[$i]\t";
					print "$url_prefix/$targetFilename\t";
					#print STDERR "$url_prefix/$targetFilename\t";
					#print STDERR "soft link target will be: $values[$i]\n";
					# $values[$i] = LID47105/LID47105_AD0DUHACXX_7_2.txt.gz
					
#comment/uncomment following line to cp files
					
					if ($copyFilesOver==1){
						system("rsync -Ra $values[$i] $local_prefix");
					}
					else{
						
						system("ln -s $dataDir/$values[$i] $local_prefix/");
					}
				}
				else{
					print STDERR "WARNING: Split files not supported, skipped: $values[$i] .\nHopefully this is just a FASTQ file split into distinct lanes.\n";
				}
				#	print STDERR "skipped rsync -Ra  $values[$i] $local_prefix\n";
				#	last;
				#}
			}
			else{
#				next unless ($values[$i]);
				$values[$i]="." unless ($values[$i]);
				print "$keys[$i]=$values[$i];";
				if($i==$#keys){
					print " type=$fileType;\n";
				}
				else{
					print " ";
				}
			}
			
		}
	}
	
}
