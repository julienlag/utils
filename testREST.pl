#!/usr/bin/perl -w

use strict;
use warnings;
use Data::Dumper;
#use HTTP::Request;
use LWP;
use JSON;
use LWP::Authen::OAuth2;

 my $oauth2 = LWP::Authen::OAuth2->new(
                     client_id => "955305639607.apps.googleusercontent.com",
                     client_secret => "62x7w00IdYHu6RBycDIxp_0N",
                     service_provider => "Google",
                     # Optional hook, but recommended.
                     save_tokens => \&save_tokens,
                     # This is for when you have tokens from last time.
                     token_string => $token_string.
                 );






my $browser = LWP::UserAgent->new;
my $url = 'https://www.googleapis.com/drive/v2/files/0AgL_RrWjAK9CdG12dHYwb1hPR2hTSWNoSTEtemdBdXc';

# Issue request, with an HTTP header
my $response = $browser->get($url,
  'User-Agent' => 'Mozilla/4.0 (compatible; MSIE 7.0)',
);
unless ($response->is_success){
 print "Error getting $url:\n"; 
 print $response->as_string."\n";
 die;
 }
print 'Content type is ', $response->content_type;
print 'Content is:';
print $response->content;
