
#use strict;
#use warnings;
#use HTTP::Request;
#use LWP;
#use lib "$ENV{'ENCODE3_PERLMODS'}";
#use prepareEncode3DccConnections;
#PATCHes a JSON object through HTTP/REST API, returns the http response (in json format)
sub patchEncode3{
 my $baseUrl = $_[0];
 my $json_whole_file = $_[1];
 my @connectParams=prepareEncode3DccConnections($baseUrl);
 my $url=$connectParams[0];
 my $authid = $connectParams[1];
 my $authpw = $connectParams[2];
 my $ua = LWP::UserAgent->new;
 print STDERR "PATCHing to $url ...";
 my $req=HTTP::Request->new(PATCH => "$url");
 $req->authorization_basic("$authid", "$authpw");
 $req->content_type('application/json');
 $req->content($json_whole_file);
 my $response=$ua->request($req);
 unless ($response->is_success){
  print STDERR "\nError patching $url :\n"; 
  print STDERR $response->as_string."\n";
  return '{}'; #empty json object
 }
 print STDERR " Done.\n";

my $json_response=$response->decoded_content;
return $json_response;

}

1;
