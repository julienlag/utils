#!/usr/bin/perl -w
use lib "/users/rg/jlagarde/julien_utils/";
use encode_metadata;
use strict;
use warnings;
use Spreadsheet::Read;
use Data::Dumper;
$|=1;

# new data in TSV = $ARGV[0]
# meta-file containing the list of columns to read from = $ARGV[1];
# old data in TSV = $ARGV[2] (optional)

my $new=$ARGV[0];
my $meta=$ARGV[1];
my $organism=$ARGV[2];
my $processNotRegistered=$ARGV[3];
die "Need to know if unregistered or blacklisted cell lines should be processed or not\n" unless ( (defined ($processNotRegistered)) && ($processNotRegistered eq 'processAll' || $processNotRegistered eq 'noProcessAll')); 
my $old=$ARGV[4] if defined ($ARGV[4]);

my @basicSampleAttr=("rnaExtract", "replicate", "localization", "donorId", "cell", "Cell line name registered at DCC"); #list of mandatory sample attributes
my @basicSampleAttr2=@basicSampleAttr;
my @mandatoryColumnsNotInOutput=();
if($processNotRegistered eq 'noProcessAll'){
	@mandatoryColumnsNotInOutput=('blacklisted','Cell line name registered at DCC');
}

open META, "$meta" or die $!;

my %mandatoryColumns;
while(<META>){
	chomp;
	my @line=split "\t";
	if ($line[0] eq "Column name"){
		shift(@line);
		foreach my $i (@line){
			$mandatoryColumns{$i}=1;
		}
		
	}
}
close META;
$mandatoryColumns{'dataType'}=1;

my %labExpId2metadataOld=();
my %labExpId2metadataNew=();

if(defined ($old)){
	%labExpId2metadataOld=encode_metadata::encode_metadata($old,1,$organism);
}

#add columns present in old file to mandatory columns
foreach my $lei (keys %labExpId2metadataOld){
	foreach my $attr (keys %{$labExpId2metadataOld{$lei}}){
		$mandatoryColumns{$attr}=1;
	}
}
delete ($mandatoryColumns{'replicate_old'});
delete ($mandatoryColumns{'rnaTreatment'});

open BLACKLIST, ">>labExpIds_blacklist.tsv" or die $!;
%labExpId2metadataNew=encode_metadata::encode_metadata($new,1,$organism);
#print Dumper \%labExpId2metadataNew;
my %labExpIdBlacklist=();
my %labExpIdToSkip=(); #different from blacklisting!!
my %labExpIds_newly_blacklisted=();
#scan %labExpId2metadataNew to detect items having mandatory attrs missing
#print STDERR "@mandatoryColumns\n";
my %foundInOld=();
foreach my $labExpId (keys %labExpId2metadataNew){
	print STDERR "$labExpId\n";
	$foundInOld{$labExpId}=0;

	#first scan to see if any sample attribute (in @basicSampleAttrr is missing (may be the case with CAGE spreadsheet, where those are taken from "Long" spreadsheet)
	if($labExpId2metadataNew{$labExpId}{'dataType'} eq 'Cage' || $labExpId2metadataNew{$labExpId}{'dataType'} eq 'RnaPet'){
		foreach my $sampleAttr (@basicSampleAttr){
			#if($foundInOld == 0){
			if(!exists $labExpId2metadataNew{$labExpId}{$sampleAttr} || !defined $labExpId2metadataNew{$labExpId}{$sampleAttr} || $labExpId2metadataNew{$labExpId}{$sampleAttr} eq ''){
				print STDERR "Basic sample attribute(s) '$sampleAttr' missing in $new for labExpId $labExpId. Assuming it's a CAGE or PET sample. Trying to find it in file '$old' based on {localization, bioRep, rnaExtract}\n";
				print STDERR Dumper $labExpId2metadataNew{$labExpId};
				
				if(!exists $labExpId2metadataNew{$labExpId}{'bioRep'} || !defined $labExpId2metadataNew{$labExpId}{'bioRep'} || $labExpId2metadataNew{$labExpId}{'bioRep'} eq '' || !exists $labExpId2metadataNew{$labExpId}{'rnaExtract'} || !defined $labExpId2metadataNew{$labExpId}{'rnaExtract'} || $labExpId2metadataNew{$labExpId}{'rnaExtract'} eq '' || !exists $labExpId2metadataNew{$labExpId}{'localization'} || !defined $labExpId2metadataNew{$labExpId}{'localization'} || $labExpId2metadataNew{$labExpId}{'localization'} eq ''){
					print STDERR "{localization, bioRep, rnaExtract} don't exist for labExpId $labExpId. SKIPPING.\n";
					last;
				}
				else{
					foreach my $labExpIdOld (keys %labExpId2metadataOld){
						#print STDERR "'OLD $labExpId2metadataOld{$labExpIdOld}{'bioRep'}' ==  NEW '$labExpId2metadataNew{$labExpId}{'bioRep'}'\n";
						
#							if($labExpId2metadataOld{$labExpIdOld}{'bioRep'} eq  $labExpId2metadataNew{$labExpId}{'bioRep'} && $labExpId2metadataOld{$labExpIdOld}{'rnaExtract'} eq $labExpId2metadataNew{$labExpId}{'rnaExtract'} && $labExpId2metadataOld{$labExpIdOld}{'localization'} eq $labExpId2metadataNew{$labExpId}{'localization'}){
						#print STDERR "Trying $labExpIdOld\n".Dumper $labExpId2metadataOld{$labExpIdOld};
						if( ($labExpId2metadataOld{$labExpIdOld}{'bioRep'} eq  $labExpId2metadataNew{$labExpId}{'bioRep'} && $labExpId2metadataOld{$labExpIdOld}{'localization'} eq $labExpId2metadataNew{$labExpId}{'localization'}) && (exists($labExpId2metadataOld{$labExpIdOld}{$sampleAttr}))){
							
							$foundInOld{$labExpId}=1;
							print STDERR "\n\n$sampleAttr FOUND IN OLD $labExpId2metadataOld{$labExpIdOld}{'bioRep'} $labExpId2metadataOld{$labExpIdOld}{'localization'}\n".Dumper $labExpId2metadataOld{$labExpIdOld};
							print STDERR "BEFORE:\n".Dumper $labExpId2metadataNew{$labExpId};
							#foreach my $sampleAttr2 (@basicSampleAttr2){
								$labExpId2metadataNew{$labExpId}{$sampleAttr}=$labExpId2metadataOld{$labExpIdOld}{$sampleAttr};
							#}
#							if(!defined $labExpId2metadataNew{'Cell line name registered at DCC'}){
#								$labExpId2metadataNew{$labExpId}{'Cell line name registered at DCC'}='y';
#								print STDERR "\nWARNING: 'Cell line name registered at DCC' attr not found in $old for $labExpId, set to 'y'\n\n";
#							}								
							
							print STDERR "AFTER:\n".Dumper $labExpId2metadataNew{$labExpId};
							last; #found!
						}
					}
#					if ($foundInOld > 1){
#						print STDERR "\n\nERROR: {localization, bioRep, rnaExtract} ($labExpId2metadataNew{$labExpId}{'localization'} , $labExpId2metadataNew{$labExpId}{'bioRep'} , $labExpId2metadataNew{$labExpId}{'rnaExtract'}) found $foundInOld times in $old for $labExpId.\n\n";
#					}
#					elsif ($foundInOld == 0){
#						print STDERR "\n\nERROR: $labExpId ($labExpId2metadataNew{$labExpId}{'localization'} , $labExpId2metadataNew{$labExpId}{'bioRep'} , $labExpId2metadataNew{$labExpId}{'rnaExtract'}) NOT FOUND IN OLD\n\n";
#						last;
#					}
#					else{
#						last;
#					}
				}
			}
			#}
		}
		$labExpId2metadataNew{$labExpId}{'Cell line name registered at DCC'}='Yes'; #should be the case if PET or CAGE (since RNASeq is run ans submitted before)
	}
	print STDERR Dumper \%foundInOld;

	foreach my $mandatoryAttr (keys %mandatoryColumns){
		if (!exists $labExpId2metadataNew{$labExpId}{$mandatoryAttr} || !defined $labExpId2metadataNew{$labExpId}{$mandatoryAttr} || $labExpId2metadataNew{$labExpId}{$mandatoryAttr} eq ''){
			if($mandatoryAttr eq 'blacklisted'){
				$labExpId2metadataNew{$labExpId}{$mandatoryAttr}='n';
				print STDERR "Mandatory attr '$mandatoryAttr' not defined for labExpId $labExpId . Set to 'n'.\n";
			}
			elsif($mandatoryAttr eq 'Cell line name registered at DCC'){
				$labExpId2metadataNew{$labExpId}{$mandatoryAttr}='n';
				print STDERR "Mandatory attr '$mandatoryAttr' not defined for labExpId $labExpId . Set to 'n'.\n";
			}
			else{
				print STDERR "Mandatory attr '$mandatoryAttr' not defined for labExpId $labExpId . Set to 'N/A'.\n";
				$labExpId2metadataNew{$labExpId}{$mandatoryAttr}='N/A';
			}
		}
		elsif($mandatoryAttr eq 'blacklisted'){
			if(check_attr_value($labExpId2metadataNew{$labExpId}{$mandatoryAttr},$labExpId,$mandatoryAttr) eq 'y'){
				print BLACKLIST "$labExpId\n";
				$labExpIdBlacklist{$labExpId}=1;
				#delete $labExpId2metadataNew{$labExpId};
				if(exists($labExpId2metadataOld{$labExpId})){ #delete also from "old" hash
					#print STDERR "CAUTION: Blacklisted $labExpId (present in old version of file $old).\n";
					$labExpIds_newly_blacklisted{$labExpId}=1;
					#delete $labExpId2metadataOld{$labExpId};
				}
			}
		}
		if($mandatoryAttr eq 'Cell line name registered at DCC'){
			if(check_attr_value($labExpId2metadataNew{$labExpId}{$mandatoryAttr},$labExpId,$mandatoryAttr) eq 'n'){
				if($processNotRegistered eq 'noProcessAll'){
					print STDERR "$labExpId : cell line marked as not registered at DCC. Skipped.\n";
					#delete $labExpId2metadataNew{$labExpId};
					$labExpIdToSkip{$labExpId}=1;
				}
			}
		}
		elsif($mandatoryAttr eq 'rnaEnzymaticTreatment' || $mandatoryAttr eq 'rnaTreatment' || $mandatoryAttr eq 'protocol'){
			$labExpId2metadataNew{$labExpId}{$mandatoryAttr} = 'None' if(uc($labExpId2metadataNew{$labExpId}{$mandatoryAttr}) eq 'UNTREAT' || uc($labExpId2metadataNew{$labExpId}{$mandatoryAttr}) eq 'UNTREATED' || uc($labExpId2metadataNew{$labExpId}{$mandatoryAttr}) eq 'NONE');
		}
		elsif($mandatoryAttr eq 'sex'){
			$labExpId2metadataNew{$labExpId}{$mandatoryAttr} = uc($labExpId2metadataNew{$labExpId}{$mandatoryAttr});
		}
	}
}

#delete blacklisted+toskip stuff from both hashes
foreach my $labExpId (%labExpIdBlacklist){
	delete($labExpId2metadataNew{$labExpId});
	delete($labExpId2metadataOld{$labExpId});
}
foreach my $labExpId (%labExpIdToSkip){
	delete($labExpId2metadataNew{$labExpId}) if exists ($labExpId2metadataNew{$labExpId});
	delete($labExpId2metadataOld{$labExpId}) if exists ($labExpId2metadataOld{$labExpId});
}



#scan %labExpId2metadataOld to detect items having mandatory attrs missing

foreach my $labExpId (keys %labExpId2metadataOld){
	foreach my $mandatoryAttr (keys %mandatoryColumns){
		if (!exists $labExpId2metadataOld{$labExpId}{$mandatoryAttr} ||!defined $labExpId2metadataOld{$labExpId}{$mandatoryAttr} || $labExpId2metadataOld{$labExpId}{$mandatoryAttr} eq ''){
			#print STDERR "Mandatory attr '$mandatoryAttr' not defined for labExpId $labExpId . Set to 'N/A'.\n";
			my $found=0;
			foreach my $i (@mandatoryColumnsNotInOutput){
				if($i eq $mandatoryAttr){
					$found=1;
					last;
				}
			}
			unless($found ==1){
				$labExpId2metadataOld{$labExpId}{$mandatoryAttr}='N/A';
			}
		}
	}
}


#merge old and new hashes (see Perl Cookbook 2nd edition recipe 5.11)
#if labExpId exists only in old, leave it untouched
my %labExpId2metadataMerged = ( );

while ( (my $labExpId,$meta) = each(%labExpId2metadataOld) ) {
    $labExpId2metadataMerged{$labExpId} = $meta;
}
#print Dumper \%labExpId2metadataMerged;
#print "that was merged\n";
my $countnewlibs=0;
while ( (my $labExpId,$meta) = each(%labExpId2metadataNew) ) {
	if(exists $labExpId2metadataMerged{$labExpId}){
		
		foreach my $k (keys %{$labExpId2metadataMerged{$labExpId}}){
			if(!exists ($labExpId2metadataNew{$labExpId}{$k})){
				print STDERR "Attr $k removed in new version for $labExpId\n";
			}
			elsif($labExpId2metadataNew{$labExpId}{$k} ne $labExpId2metadataMerged{$labExpId}{$k}){
				print STDERR "METADATA CONFLICT for $labExpId:\n\told $k =  $labExpId2metadataMerged{$labExpId}{$k}\n\treplaced by\n\tnew $k =  $labExpId2metadataNew{$labExpId}{$k}\n";
			}
		}
	}
	else{
		$countnewlibs++;
		#print STDERR "$labExpId is new. Adding it to output.\n";
	}
	$labExpId2metadataMerged{$labExpId} = $meta;
	#}
}

#print Dumper \%labExpId2metadataMerged;
#print "that was merged\n";
if($processNotRegistered eq 'noProcessAll'){
	delete($mandatoryColumns{'Cell line name registered at DCC'});
	delete($mandatoryColumns{'blacklisted'});
}
#print header:
print "#";
my @attr = sort (keys %mandatoryColumns);
print join ("\t", @attr);
print "\n";
#print data
foreach my $labExpId (keys %labExpId2metadataMerged){
	my @values=();
	#print STDERR "$labExpId\n";
	foreach my $key (@attr){
		if(uc($labExpId2metadataMerged{$labExpId}{$key}) eq 'Y' ||uc($labExpId2metadataMerged{$labExpId}{$key}) eq 'YES'){
			$labExpId2metadataMerged{$labExpId}{$key}='y'
		}
		elsif(uc($labExpId2metadataMerged{$labExpId}{$key}) eq 'N' ||uc($labExpId2metadataMerged{$labExpId}{$key}) eq 'NO'){
			$labExpId2metadataMerged{$labExpId}{$key}='n'
		}
		push(@values, $labExpId2metadataMerged{$labExpId}{$key});
	}
	#print join ("\t", @attr)."\n";
	print join ("\t", @values)."\n";
}
my @removed=keys (%labExpIds_newly_blacklisted);
print STDERR "\n\n$countnewlibs libs added.\n".@removed." removed (also added to blacklist): ";
print STDERR join(", ", @removed)." .\n\n";

sub check_attr_value{

	my $value=$_[0];
	my $labExpId=$_[1];
	my $mandAttr=$_[2];
	if(uc($value) eq 'YES' || uc($value) eq 'Y'){
		return 'y';
	}
	elsif(uc($value) eq 'NO' || uc($value) eq 'N'){
		return 'n';
	}
	else{
		die "labExpId $labExpId: Unrecognized value '$value' for attr '$mandAttr'\n";
	}
}
