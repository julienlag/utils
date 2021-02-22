#!/usr/bin/perl -w

# create GFF file with gene, transcript, exon, intron features
# from OTTER database using DAS

use strict;
use Bio::Das::Lite;
use Getopt::Long;

my $startt = time();

#default DAS server adress
my $server = "http://das.sanger.ac.uk/das";
#default DAS source name
my $source = 'otter_das';
#proxy name
my $http_proxy;
#genomic chunk size to query
my $max_len    = 20000000;

my $chromosome = undef;
my $start      = 0;
my $end        = 0;
my $gff_file   = undef;

my ($filter_gene_biotype, $filter_gene_status, $filter_transcript_biotype, $filter_transcript_status, $types, $type);
my ($filter_no_gene_biotype, $filter_no_gene_status, $filter_no_transcript_biotype, $filter_no_transcript_status);
my $help = 0;
my $like = 0;

my %transcripts = ();

&GetOptions(
            'help!'                  => \$help,
	    'file=s'                 => \$gff_file,
	    'chromosome=s'           => \$chromosome,
	    'start=s'                => \$start,
	    'end=s'                  => \$end,
	    'gene_type=s'            => \$filter_gene_biotype,
	    'gene_status=s'          => \$filter_gene_status,
	    'transcript_type=s'      => \$filter_transcript_biotype,
	    'transcript_status=s'    => \$filter_transcript_status,
	    'no_gene_type=s'         => \$filter_no_gene_biotype,
	    'no_gene_status=s'       => \$filter_no_gene_status,
	    'no_transcript_type=s'   => \$filter_no_transcript_biotype,
	    'no_transcript_status=s' => \$filter_no_transcript_status,
            'server=s'               => \$server,
            'source=s'               => \$source,
            'http_proxy=s'           => \$http_proxy,
            'types'                  => \$types,
            'type=s'                 => \$type,
	    'like!'                  => \$like,
	   );

if(!$types and ($help or !$gff_file or ($start and !$end) or (!$start and $end) or (!$chromosome and ($start or $end) )) ){
  print `perldoc $0`;
  exit 1;
}

#connect to DAS server
my $das = connect_das("$server/$source", $http_proxy);

if($types){
  my $response = $das->types();
  while (my ($url, $features) = each %$response) {
    if(ref $features eq "ARRAY"){
      print STDERR "Received ".scalar @$features." features.\n";
      foreach my $feature (@$features) {
	foreach my $key (sort keys %$feature){
	  print "$key $feature->{$key}\n";
	}
	print "\n";
      }
    }
  }
  exit;
}

#get entry point list/lengths
my $chrom_lens = get_entry_points();

open(GFF, ">$gff_file") or die "Can't open file $gff_file.\n";

if($chromosome){
  #query specific region
  get_region($chromosome, $start, $end);
}
else{
  #go through all chromosomes	
  foreach my $chrom (keys %$chrom_lens){
	print "getting $chrom\n";
	get_region($chrom, undef, undef);
	%transcripts = ();
  }
}

close(GFF)or die "Can't close file $gff_file.\n";

my $endt = time();
print "Time taken was ", ($endt - $startt), " seconds\n\n";


  ################################################


sub connect_das {
  my ($dsn, $proxy) = @_;

  my $das = Bio::Das::Lite->new({
				 'timeout'    => 10000,
				 'dsn'        => $dsn,
				 'http_proxy' => $proxy,
				}) or die "cant connect to DAS server!\n";

  return $das;
}


sub get_region {
  my ($chromosome, $start, $end) = @_;

  my $chrom_len    = $chrom_lens->{$chromosome};
  my $region       = "";

  if( $start and $end){
    if($start > $end){
      die "Coordinates wrong: $start > $end!\n";
    }
    if( ($end - $start) <= $max_len ){
      #get entire region
      my $region = ":".$start.",".$end;
      get_transcripts($region, $chromosome);
    }
    else{
      go_through_chunks($start, $end, $chromosome, $chrom_len);
    }
  }
  elsif( $chrom_len <= $max_len ){
    #get entire chromosome
    get_transcripts($region, $chromosome);
  }
  else{
    go_through_chunks(1, $chrom_len, $chromosome, $chrom_len);
  }

}


sub go_through_chunks {
  my ($chunk_start, $chunk_end, $chromosome, $chrom_len) = @_;

  my ($region_start, $region_end);
  my %ids_seen;

  #loop through regions until all is covered
  #keep track of genes to avoid duplicates!
  for($region_start = $chunk_start, $region_end = $region_start + $max_len;
      $region_start < $chunk_end;
      $region_start = $region_end + 1, $region_end += $max_len){

    if($region_end > $chrom_len){
      $region_end = $chrom_len;
    }elsif($region_end > $chunk_end){
      $region_end = $chunk_end;
    }
    my $region = ":".$region_start.",".$region_end;

    #get all transcripts from chunk
    my $new_ids = get_transcripts($region, $chromosome, \%ids_seen);
    %ids_seen = (%ids_seen, %$new_ids);
  }

}


sub get_entry_points {

  my %chrom_lens;

  my $entry_points = $das->entry_points();

  foreach my $k (keys %$entry_points){
	foreach my $l (@{$entry_points->{$k}}){
		foreach my $segment (@{ $l->{"segment"} }){
			#print $segment->{"segment_id"}.": ".$segment->{"segment_size"}."\n";
			$chrom_lens{ $segment->{"segment_id"} } = $segment->{"segment_size"};
		}
  	}
  }

  return \%chrom_lens;
}


sub get_transcripts {
  my ( $region, $chromosome, $previous_genes ) = @_;


  print STDERR "have chr $chromosome$region\n";

  my %genes = ();
  my %new_features = ();
  my $response = undef;

  #fetch DAS features
  $response = $das->features({
			      'segment' => $chromosome.$region,
			      'type'    => $type,
			     });

  while (my ($url, $features) = each %$response) {

    if(ref $features eq "ARRAY"){
      print STDERR "Received ".scalar @$features." features.\n";

    FEATURES:
      foreach my $feature (@$features) {

	my %notes = ();

	#if($feature->{'type_category'} =~ /error_transcript/){
	  #print STDERR "Ignore an error feature!\n";
	  #print_gff_line(\%gff_element);
	  #next FEATURES;
	#}

	#get transcript & gene biotype
#	my $gene_typestring = $feature->{'note'}->[0];
#	my ($gene_type_s, $gene_type, $gene_status) = split('=', $gene_typestring);

#	my $transcript_typestring = $feature->{'note'}->[1];
#	my ($transcipt_type_s, $transcript_type, $transcript_status) = split('=', $transcript_typestring);

	my $grouphash = $feature->{'group'}->[0];

#	#get transcript timestamp
#	my $transcript_timestamp = $feature->{'note'}->[2];
#	my ($timestamp_s, $timestamp) = split('=', $transcript_timestamp);

	#get other notes
	my $i = 0;
	my $morenote_entry = '';
	while(defined($feature->{'note'}->[$i])){
	  my $morenotes = $feature->{'note'}->[$i];
	  my ($morenotes_type, $morenotes_value) = split('=', $morenotes);
	  $morenotes_value =~ s/\&\#39\;/\'/g;
	  $notes{$morenotes_type} = $morenotes_value;
	  $i++;
	}

	#remove duplicates from overlapping regions
	if(defined $previous_genes and exists($previous_genes->{$grouphash->{'group_type'}})){
	  next FEATURES;
	}

	#check filter criteria
	#gene type
	if($filter_gene_biotype && !$like && ($notes{"Genetype"} ne $filter_gene_biotype)){
	  next FEATURES;
	}
	#"like" gene type
	if($filter_gene_biotype && $like && !($notes{"Genetype"} =~ /$filter_gene_biotype/)){
	  next FEATURES;
	}
	#gene status
	if($filter_gene_status && ($filter_gene_status ne $notes{"Gene_status"})){
	  next FEATURES;
	}
	#transcript type
	if($filter_transcript_biotype && !$like  && ($filter_transcript_biotype ne $notes{"Transcripttype"})){
	  next FEATURES;
	}
	#"like" transcript type
	if($filter_transcript_biotype && $like && !($notes{"Transctiptype"} =~ /$filter_transcript_biotype/)){
	  next FEATURES;
	}
	#transcript status
	if($filter_transcript_status && ($filter_transcript_status ne $notes{"Transcript_status"})){
	  next FEATURES;
	}
	#negative gene type
	if($filter_no_gene_biotype && ($filter_no_gene_biotype eq $notes{"Genetype"})){
	  next FEATURES;
	}
	#negative "like" gene type
	if($filter_no_gene_biotype && !($notes{"Genetype"} =~ /$filter_no_gene_biotype/)){
	  next FEATURES;
	}
	#negative gene status
	if($filter_no_gene_status && ($filter_no_gene_status eq $notes{"Gene_status"})){
	  next FEATURES;
	}
	#negative transcript type
	if($filter_no_transcript_biotype && ($filter_no_transcript_biotype eq $notes{"Transcripttype"})){
	  next FEATURES;
	}
	#negative "like" transcript type
	if($filter_no_transcript_biotype && $like && !($notes{"Transcripttype"} =~ /$filter_no_transcript_biotype/)){
	  next FEATURES;
	}
	#negative transcript status
	if($filter_no_transcript_status && ($filter_no_transcript_status eq $notes{"Transcript_status"})){
	  next FEATURES;
	}

	my %gff_element;

	#build structure for exons and general items
	#find type
	my $element_type = $feature->{'type'} || "exon";
	$element_type    =~ m/((intron)|(UTR)|(exon))/g;
	if($1){ $element_type = $1 }

	my $group_type   = $grouphash->{'group_type'};

	my $strand       = $feature->{'orientation'};
	if($feature->{'orientation'}    =~ /^(\+|\-|\.)$/) {  }
	elsif($feature->{'orientation'} ==  1){ $strand = '+' }
	elsif($feature->{'orientation'} == -1){ $strand = '-' }
	elsif($feature->{'orientation'} ==  0){ $strand = '.' }
	else{ die "INVALID STRAND SYMBOL: ".$feature->{'orientation'}."\n"; }

	my $phase        = ".";
	if($feature->{'phase'}){
	  $phase = $feature->{'phase'};
	}
	elsif($element_type eq "exon"){
	  $phase = "0";
	}

	#print "Note=".join(", ", @{$grouphash->{'group_type'}})."\n";
	if(!$notes{"Transcriptstatus"}){
	  die "PROBLEM: $element_type, ".$feature->{'feature_id'}."\n";
	}

	$gff_element{'seqid'}      = $chromosome;
	$gff_element{'source'}     = $notes{"Transcripttype"};
	$gff_element{'type'}       = $element_type;
	$gff_element{'start'}      = $feature->{'start'};
	$gff_element{'end'}        = $feature->{'end'};
	$gff_element{'score'}      = ".";
	$gff_element{'strand'}     = $strand;
	$gff_element{'phase'}      = $phase;
	$gff_element{'attributes'} = "Parent=".$feature->{'feature_id'}.
	                             ";Status=".$notes{"Transcriptstatus"}.
				     ";CREATED=".$notes{"Created"}.
				     ";LASTMOD=".$notes{"Lastmod"};

	if(!exists $genes{ $group_type }){
	  $genes{ $group_type } = 1;
	  my %gff_gene;

          my $gene_region = $feature->{'target'};
          my ($gs, $gene_loc) = split('\=', $gene_region);
	  my ($gene_start, $gene_end) = split('\-', $gene_loc);

	  #build structure for gene
	  $gff_gene{'seqid'}      = $chromosome;
	  $gff_gene{'source'}     = $notes{"Genetype"};
	  $gff_gene{'type'}       = "gene";
	  $gff_gene{'start'}      = $gene_start;
	  $gff_gene{'end'}        = $gene_end;
	  $gff_gene{'score'}      = ".";
	  $gff_gene{'strand'}     = $strand;
	  $gff_gene{'phase'}      = ".";

	  #get gene description
	  my $description = "";
	  foreach my $gnote (@{$grouphash->{'note'}}){
	    my ($gnote_s, $gnote_string) = split('=', $gnote);
	    if($gnote_s eq "DESCR"){
	      $description = ";Description=".$gnote_string;
	    }
	  }
	  $gff_gene{'attributes'} = "ID=".$grouphash->{'group_type'}.
	                            $description.
				    ";Status=".$notes{"Genestatus"}.
	                            ";CREATED=".$notes{"Created"}.
				    ";LASTMOD=".$notes{"Lastmod"};

	  #print entry for transcript
	  print_gff_line(\%gff_gene);
	  %gff_gene = ();

	  $new_features{$grouphash->{'group_type'}} = 1;

	}

	if(!exists $transcripts{ $feature->{'feature_id'} }){
	  $transcripts{ $feature->{'feature_id'} } = 1;
	  my %gff_transcript;

	  #build structure for transcript
	  $gff_transcript{'seqid'}      = $chromosome;
	  $gff_transcript{'source'}     = $notes{"Transcripttype"};
	  $gff_transcript{'type'}       = "transcript";
	  $gff_transcript{'start'}      = $feature->{'target_start'};
	  $gff_transcript{'end'}        = $feature->{'target_stop'};
	  $gff_transcript{'score'}      = ".";
	  $gff_transcript{'strand'}     = $strand;
	  $gff_transcript{'phase'}      = ".";
	  $gff_transcript{'attributes'} = "ID=".$feature->{'feature_id'}.";Alias1=".$feature->{'target_id'}.
	                                  ";Parent=".$grouphash->{'group_type'}.
					  ";CREATED=".$notes{"Created"}.
					  ";LASTMOD=".$notes{"Lastmod"}.
					  ";Status=".$notes{"Transcriptstatus"};

	  #print entry for transcript
	  print_gff_line(\%gff_transcript);
	  %gff_transcript = ();
	}
	#else{ print STDERR "_" }

	#print entry for exons, etc.
	if($feature->{'type_category'} =~ /error/){
	  print STDERR "Found an error feature:\n";
	  print STDERR $gff_element{'seqid'}."\t";
	  print STDERR $gff_element{'source'}."\t";
	  print STDERR $gff_element{'type'}."\t";
	  print STDERR $gff_element{'start'}."\t";
	  print STDERR $gff_element{'end'}."\t";
	  print STDERR $gff_element{'score'}."\t";
	  print STDERR $gff_element{'strand'}."\t";
	  print STDERR $gff_element{'phase'}."\t";
	  print STDERR $gff_element{'attributes'}."\n";
	} else {
	  print_gff_line(\%gff_element);
	  %gff_element = ();
	}

	$feature = undef;
      }
      @$features = ();
      $features  = undef;
    }
  }

  return \%new_features;
}


sub print_gff_line {
  my ($element) = @_;

  print GFF $element->{'seqid'}."\t";
  print GFF $element->{'source'}."\t";
  print GFF $element->{'type'}."\t";
  print GFF $element->{'start'}."\t";
  print GFF $element->{'end'}."\t";
  print GFF $element->{'score'}."\t";
  print GFF $element->{'strand'}."\t";
  print GFF $element->{'phase'}."\t";
  print GFF $element->{'attributes'}."\n";
}




1;

__END__

=head1 NAME

genes_das2gff

=head1 DESCRIPTION

Script to create GFF file with gene, transcript, exon, intron features
from OTTER database using DAS.

You can use positive and negative filtering on gene and transcript type and status.

Format: GFF3

Fields:
seqid (Chromosome), source (type of gene or transcript), type (exon, intron or UTR), start, end, score (unused), strand, phase (-,0,1,2), attributes (transcript-ids, gene-ids, gene-description, status of gene or transcript, last-midified date of transcript)

Using the additional -like argument, the gene_type, no_gene_type, transcript_type and no_transcript_type arguments can use pattern matching so that "pseudogene" will find "pseudogene" as well as "processed_pseudogene".

seperated by TAB

If there are problems transforming features to the current assembly, there will be an ERROR note in the last column. The coordinates can not be fully trusted in these cases.

For larger regions to response is automatically split into subregions, the output will still be combined in the file specified.

If no chromosome is specified, the script will go through all (main) chromosomes.

You can also use the script to find out about available sources on a DAS server if it implements this command:
 perl genes_das2gff.pl -types \
  -server http://hgwdev-gencode.cse.ucsc.edu/cgi-bin/das -source hg18



=head1 VERSION

5

=head1 SYNOPSIS

perl genes_das2gff.pl -file genes.gff
   [optional:]  -chrom 22 -start 43343883 -end 43346754
                -gene_type xx -gene_status xx -transcript_type xx
                -transcript_status xx -no_gene_type xx
                -no_gene_status xx -like
                -no_transcript_type xx -no_transcript_status xx

=head1 AUTHOR

Felix Kokocinski, fsk@sanger.ac.uk

=cut

