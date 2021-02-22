#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use FindBin;    # find present script
use lib "$FindBin::Bin";
use processJsonToHash;
use HTTP::Request::Common;
use LWP::UserAgent;    # install LWP::Protocol::https as well

my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );
my ( $user, $pass, $auth_token ) = ( $ARGV[0], $ARGV[1] );
my $jsonFile = $ARGV[2];
my $server   = 'https://www.trackhubregistry.org';
$auth_token = login( $server, $user, $pass );

my $trackJson = processJsonToHash($jsonFile);

my $request = POST(
    "$server/api/trackhub",
    'Content-type' => 'application/json',
    'Content'      => to_json($trackJson)
);
$request->headers->header( user       => $user );
$request->headers->header( auth_token => $auth_token );
my $response = $ua->request($request);
if ( $response->is_success ) {
    print "I have registered hub at $$trackJson{'url'}\n";
}
else {
    die sprintf "Couldn't register hub at $$trackJson{'url'}: %s [%d]",
        $response->content, $response->code;
}

logout( $server, $user, $auth_token );

sub login {
    my ( $server, $user, $pass ) = @_;

    my $request = GET("$server/api/login");
    $request->headers->authorization_basic( $user, $pass );

    my $response = $ua->request($request);
    my $auth_token;
    if ( $response->is_success ) {
        $auth_token = from_json( $response->content )->{auth_token};
        print "Logged in [$auth_token]\n" if $auth_token;
    }
    else {
        die sprintf "Couldn't login: %s [%d]", $response->content,
            $response->code;
    }

    return $auth_token;
}

sub logout {
    my ( $server, $user, $auth_token ) = @_;

    my $request = GET("$server/api/logout");
    $request->headers->header( user       => $user );
    $request->headers->header( auth_token => $auth_token );

    my $response = $ua->request($request);
    if ( $response->is_success ) {
        print "Logged out\n";
    }
    else {
        die sprintf "Unable to logout: %s [%d]", $response->content,
            $response->code;
    }
}
