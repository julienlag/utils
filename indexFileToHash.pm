use strict;
use warnings;

sub indexFileToHash{
	open INDEX, "$_[0]" or die $!;
	my %index=();
	while(<INDEX>){
		chomp;
		next if ($_=~/^#/);
		if($_=~/^(\S+)\t(.*)$/){
			my $line=$_;
			$line=~s/;$//g;
			my @line=split("\t", $line);
			my $filepath=shift(@line);
			my @attrs=split("; ", $line[0]);
			#print "$filepath ".Dumper \@attrs;
			if(exists ($index{$filepath})){
				die "DEATH: duplicate file path found: $filepath\n";
			}
			for (my $i=0; $i<=$#attrs;$i++){
				if($attrs[$i]=~/(\S+?)=(.+)/){ # key pattern mus be non-greedy, so that values containing '=' signs (e.g. URLs) don't fuck up everything. Supposedly key swill never contain = signs
					my $key=$1;
					my $value=$2;
					if(exists (${$index{$filepath}}{$key})){
						warn "Multiple instances of attribute '$key' found at line $.:\n$_\nOnly the last encountered instance ('$key=$value') will be output.\n"
					}
					${$index{$filepath}}{$key}=$value;
				}
				else{
					warn "WARNING: Malformed 'key=value;' pair ('$attrs[$i]') at line $. Attribute skipped. :\n$_\n";
				}

			}
		}
		else{
			die "DEATH: Malformed at line $.:\n$_\n";
		}
	}
	close INDEX;
	return %index;
}


1;
