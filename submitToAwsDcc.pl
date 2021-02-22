#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use JSON;
use lib "/users/rg/jlagarde/julien_utils/";
use processJsonToHash;

$|=1;

my $sysStdout=$ARGV[0].".out";
my $sysStderr=$ARGV[0].".err";

my $jsonPostResponseTree = processJsonToHash($ARGV[0]);
$ARGV[0]=~/(\S+)\.json\.postResponse\.json/;
my $fileToSubmit=$1;
my $uploadUrl;
my $nonEmptyInputJson=0;
foreach my $i (@{$$jsonPostResponseTree{'@graph'}}){
	if(exists $$i{'upload_credentials'}){ # quick and dirty way to check if POST was successful
		$nonEmptyInputJson=1;
	  $ENV{'AWS_ACCESS_KEY_ID'}=$$i{'upload_credentials'}{'access_key'};
  	$ENV{'AWS_SECRET_ACCESS_KEY'}=$$i{'upload_credentials'}{'secret_key'};
  	$ENV{'AWS_SECURITY_TOKEN'}=$$i{'upload_credentials'}{'session_token'};
#  	$fileToSubmit=$$i{'submitted_file_name'};
  	$uploadUrl=$$i{'upload_credentials'}{'upload_url'};
  }
}

if($nonEmptyInputJson){
	print STDERR "Uploading $fileToSubmit to $uploadUrl...\n";
	my $awsReturnCode=system("/users/rg/jlagarde/.local/bin/aws s3 cp $fileToSubmit $uploadUrl 1> $sysStdout 2> $sysStderr");
	unless($awsReturnCode == 0){
		die "aws command returned non-zero status. This probably means that the file upload failed.\n";
	}
	else{
		print STDERR "aws returned 0 exit status. Upload successful.\n";
	}
}
else{
	die "POST doesn't seem to have worked. Cannot proceed with file upload. Check $sysStdout and $sysStderr for more info.\n "
}

