

#use strict;
#use warnings;
#use HTTP::Request;
#use LWP;
use LWP::UserAgent::Determined;
use IO::Handle; #required for show_progress to work
#use lib "$ENV{'ENCODE3_PERLMODS'}";
#use prepareEncode3DccConnections;
#fetches a JSON object through HTTP/REST API, and returns it
sub getEncode3{
 my $baseUrl = $_[0];
 my @connectParams=prepareEncode3DccConnections($baseUrl);
 my $url=$connectParams[0]."?frame=object&limit=all&format=json";
 my $authid = $connectParams[1];
 my $authpw = $connectParams[2];
 my $ua = LWP::UserAgent::Determined->new;
 $ua->show_progress("1");
 print STDERR "Downloading $url ...";
 my $req=HTTP::Request->new(GET => "$url");
 $req->authorization_basic("$authid", "$authpw");


 my $response=$ua->request($req);
 print STDERR " (HTTP response: ".$response->status_line."). ";
 unless ($response->is_success){
  print STDERR "\nError getting $url:\n"; 
  print STDERR $response->as_string."\n";
  return '{}'; #empty json object
 }
 print STDERR " Done.\n";
my $json_object=$response->decoded_content;
 return $json_object;

}

1;
