#!/usr/bin/perl -w
use strict;
use warnings;
use Mail::Sendmail;
use Net::SMTP::SSL;
use Mail::Sendmail qw(sendmail %mailcfg);
#use MIME::Base64; 
#use Authen::SASL;
my $smtpserver	     = "owa.crg.es";
my $smtpport	     = 587;
my $sender		     = "JL-perl-mailer <julien.lagarde\@crg.es>";
my $subject		     = "test";
#my $recipient	     = "Julien <julien.lagarde\@crg.es>";
# my $recipient2	     = ""; #"Julien <julienlag\@gmail.com>";
my @recipients	     = ();#$recipient, $recipient2);
my $administrator	     = "admin <julien.lagarde\@crg.es>";
my $administrator2	     = ""; #"admin <julienlag\@gmail.com>";
my @administrators= ($administrator, $administrator2);
#my $replyto		     = $sender;
#my $replyto2	     = $recipient;
#my @replytos	     = ($replyto, $replyto2);
my $header		     = "X-Mailer";
my $headervalue	     = "Perl Sendmail";
my $body	     = "Something went wrong";
my $fileattach= undef;
my $inline="";

while(<>){
	chomp;
	my @line= split "\t";
	if($line[0] eq "sender"){
		$sender=$line[1];
	}
	elsif ($line[0] eq "subject"){
		$subject=$line[1];
	}
	elsif($line[0] eq "recipient"){
		@recipients=split(",",$line[1]);
	}
	elsif($line[0] eq "fileattach"){
		$fileattach=$line[1];
	}
	elsif($line[0] eq "body"){
		$body=$line[1];
	}
	elsif($line[0] eq "inline"){
		$inline=$line[1];
	}
	else{
		print STDERR "Malformed line in input\n$_\n";
	}
}

#put file attachment inline:
if($fileattach){
	open F, "$fileattach" or die $!;
	my @tmp=<F>; 
	my $tmp=join("", @tmp);
	$body.=$tmp;
	close F;
}

# my $smtps = Net::SMTP::SSL->new($smtpserver, 
# 								Port => $smtpport,
# 								DEBUG => 1,
# 	) or warn "$!\n"; 
# defined ($smtps->auth('jlagarde', '')) or die "Can't authenticate: $!\n";
# $smtps->mail($sender);
# $smtps->to($recipients[0]);
# $smtps->data();
# $smtps->datasend("To: $recipients[0]\n");
# $smtps->datasend(qq^From: $sender"\n^);
# $smtps->datasend("Subject: $subject\n\n");
# $smtps->datasend("$body");
# $smtps->dataend();
# $smtps->quit();

# print "done\n";

$body="FROM_JL-perl-mailer\n".$body;
$mailcfg{debug} = 6;
my %mail = (
	From => $sender,
	To => $recipients[0],
	Subject => $subject,
	Message => $body,
	Auth => $sender
	);

$mail{Smtp} = Net::SMTP::SSL->new($smtpserver, Port=> $smtpport, Debug=>1);
$mail{auth} = {user=>'jlagarde', password=>"blabla", required=>1 };

sendmail(%mail) or die $Mail::Sendmail::error;

print "OK. Log says:\n", $Mail::Sendmail::log;

# my $sm = new SendMail();
# $sm = new SendMail($smtpserver);
# $sm = new SendMail($smtpserver,	$smtpport);

# $sm->setDebug($sm->ON);
# $sm->From($sender);
# $sm->Subject($subject);
# $sm->To(@recipients);
# $sm->ErrorsTo(@administrators);
# $sm->ReplyTo($sender);
# $sm->setMailHeader($header, $headervalue);
# $sm->setMailBody($body);
# $sm->Attach($fileattach);
# $sm->Inline($inline);
# $sm->setAuth($sm->AUTHLOGIN, 'jlagarde', 'blabla');
# if ($sm->sendMail() != 0) {
#   print $sm->{'error'}."\n";
#   exit -1;
# }

# #
# # Mail sent successfully.
# #
# print "Done\n\n";
exit 0;
