
#use strict;
#use warnings;

sub prepareEncode3DccConnections{
	my $baseUrl = $_[0];
	my $credentialsFile=$ENV{'ENCODE3_CREDENTIALS_FILE'};
	$baseUrl=~s/\/+$//; #trim final "/" to avoid duplicates when building the full URL
	my $url=$baseUrl;#."?frame=embedded&limit=all&format=json";
	open F, "$credentialsFile" or die $!;
	my $authid='';
	my $authpw='';
	while (<F>){
		chomp;
		if(	$_=~/(\S+) (\S+)/){
			$authid=$1;
			$authpw=$2;
			last;
		}
		else{
			die "Malformed file $credentialsFile. Cannot continue.\n"
		}
	}
	return ($url, $authid, $authpw)

}

1;
