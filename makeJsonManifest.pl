#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use FindBin;    # find present script
use Getopt::Long;
use lib "$ENV{'ENCODE3_PERLMODS'}";
use lib "$FindBin::Bin"
    ;           # include script's directory (where processJsonToHash.pm is)
use JSON;       # try to use JSON::XS instead, it's cleaner
use processJsonToHash;
$| = 1;

my $seqPlatform;    #only for FASTQs
my $assembly;       #only for BAMs or VCFs

GetOptions(
    'seqPlatform=s' => \$seqPlatform,
    'assembly=s'    => \$assembly
) or die("Error in command line arguments\n");

my %file_format_to_output_type = (
    'fastq' => 'reads',
    'bam'   => 'alignments',
    'vcf'   => 'variant calls'
);

my %file_metadata = ();

#print Dumper \%file_format_to_output_type;

#read RAMPAGE (or other) metadata TSV

open META, "$ARGV[2]" or die $!;

my $libField;
my $barcodeField;
my %enclbToBarcodeSet = ();
while (<META>) {
    if ( $_ =~ /^#/ ) {    #found header
        my @line = split "\t";

        #search for needed metadata
        for ( my $i = 0; $i <= $#line; $i++ ) {
            if ( $line[$i] eq 'DCC Library Accession #' ) {
                $libField = $i;
            }
            elsif ( $line[$i] eq 'Index Sequence(s) Multiplex' ) {
                $barcodeField = $i;
            }
        }
    }
    else {
        my @line = split "\t";
        if ( $line[$libField] =~ /ENCLB/ ) {
            $line[$libField] =~ s/\s//g;
            if ( $line[$barcodeField] =~ /(index\S+)/ ) {
                my $tmp = $1;
                $tmp =~ s/index\d+//g;
                $tmp =~ s/\s//g;
                my @barcodes = split( "-", $tmp );
                foreach my $bcode (@barcodes) {
                    die
                        "non-nucleotide barcode detected in $ARGV[2]: '$bcode' , can't continue.\n"
                        unless ( $bcode =~ /[ACGTacgt]+/ );
                }
                print $line[$libField] . "   "
                    . join( ",", @barcodes ) . "\n";
                $enclbToBarcodeSet{ $line[$libField] } = \@barcodes;
            }
        }
    }
}
close META;

#print Dumper \%enclbToBarcodeSet;

print STDERR "Reading collection in...";
my $objects_tree = processJsonToHash( $ARGV[1] );
print STDERR " done.\n";

open SUBFILES, "$ARGV[0]" or die $!;
while (<SUBFILES>) {
    chomp;
    my $filename = $_;
    print STDERR "Gathering metadata for $filename ...\n";
    my $file_size     = -s $filename;
    my %controlled_by = ();

    #print STDERR "Filesize= $file_size\n";
    if (   $filename =~ /(.*)(ENCLB[0-9a-zA-Z]+)(?:_)*(\S+)$/
        || $filename =~ /(.*)(ENCSR[0-9a-zA-Z]+)(?:_)*(\S+)$/ )
    {

        my $md5checksum = $filename . ".md5";
        my $path        = $1;
        my $encID       = $2;
        my $rest        = $3;
        my $encID_type;
        if ( $encID =~ /ENCLB.+/ ) {
            $encID_type = 'lib';
        }
        elsif ( $encID =~ /ENCSR.+/ ) {
            $encID_type = 'exp';
        }
        else {
            die;
        }
        my $file_format;
        my $paired_end;
        my $run_type;    # = 'unknown';
        my $haplotype; #maternal or paternal
        my @rest = split( /\./, $rest );

        while (@rest) {    # loop over suffix elements backwards
            my $item = pop @rest;
            if ( $item eq "gz" || $item eq "tgz" || $item eq "tar" ) {
                next;
            }
            elsif ($item eq 'fastq'
                || $item eq 'fq'
                || $item eq 'bam'
                || $item eq 'vcf'
                || $item eq 'chain'
                || $item eq 'fa' )
            {
                $file_format = $item;
            }
            elsif ( $item =~ /.*([1-2])$/ ) {
                $paired_end = $1;
            }
            elsif($item eq 'maternal' || $item eq 'paternal'){
                $haplotype=$item;
            }
        }
        print STDERR "File format: $file_format\n";
        my $output_type;
        if ( exists $file_format_to_output_type{$file_format} ) {
            $output_type = $file_format_to_output_type{$file_format};
        }
        elsif( (defined ($haplotype)) && ($haplotype eq 'maternal' || $haplotype eq 'paternal')){
            if ($file_format eq 'fa'){

            }
            elsif ($file_format eq 'chain'){

            }
            else{
                die "If haplotype is defined ('$haplotype' here), file format must be 'chain' of 'fa'. Can't continue.\n"
            }
        }
        else {
            die
                "No output_type found for file_format '$file_format'. Edit script.\n";
        }

        open MD5, "$md5checksum" or die "$md5checksum $!";
        my $md5sum;
        while (<MD5>) {
            chomp;
            if ( $_ =~ /(\S+)\s+$filename$/ ) {

                $md5sum = $1;
            }
            else {
                die
                    "Couldn't find filename ($filename) in $md5checksum. Aborting.\n";
            }
        }
        close MD5;

        my $dataset;
        my $replicate_uuid;
        my $replicate_number;
        my $read_length;
        my $barcode;
        my $unique_instrument_name;
        my $flowcell_id;
        my $flowcell_lane;

#      print "$library\n";
#get flowcell info etc. from read IDs (https://en.wikipedia.org/wiki/FASTQ_format#Illumina_sequence_identifiers, Casava 1.8 version).
        if ( $file_format eq 'fastq' ) {
            die
                "Specify seqPlatform option (with --seqPlatform=\"HiSeq 2500\", --seqPlatform=\"Illumina\\ NextSeq\\ 500\")  for this FASTQ submission batch.\n"
                unless ( defined($seqPlatform) );
            if ( defined($assembly) ) {
                warn
                    "assembly option ignored (not applicable to FASTQ files)\n";
                $assembly = undef;
            }
            if ( defined $paired_end ) {
                $run_type = 'paired-ended';
            }
            else {
                $run_type = 'single-ended';
            }
            open FASTQ, "zcat $filename | head -n1|"
                or die "$filename : $!\n";
            $barcode = '';
            while (<FASTQ>) {
                chomp;
                if ( $_ =~ /^@/ ) {
                    my $line = substr( $_, 1 );    #remove first char
                    my @read_id              = split( ' ', $line );
                    my @read_id_first_field  = split( ':', $read_id[0] );
                    my @read_id_second_field = split( ':', $read_id[1] );
                    $unique_instrument_name = $read_id_first_field[0];
                    $flowcell_id            = $read_id_first_field[2];
                    $flowcell_lane          = $read_id_first_field[3];
                    $barcode                = $read_id_second_field[3];
                }
                else {
                    die "Couldn't read read_id in file $filename.\n";
                }
            }
            close FASTQ;

            #get read length via sequence of first read
            open FASTQ, "zcat $filename |head -n2|tail -n1 |"
                or die "$filename : $!\n";
            while (<FASTQ>) {
                chomp;
                $read_length = length($_);
            }
            $read_length
                += 0;    # numify it, ensuring it will be dumped as a number
            close FASTQ;
            print STDERR "read length in FASTQ: $read_length\n";
        }
        else {
            if ( defined($seqPlatform) ) {
                warn
                    "seqPlatform option ignored (not applicable to non-FASTQ files)\n";
                $seqPlatform = undef;
            }
            if ( defined $paired_end ) {
                warn
                    "paired-end info detected in non-FASTQ filename. This is probably a filename parsing error. paired_end value ignored\n";
                $paired_end = undef;
            }
            if ( $file_format eq 'bam' ) {
                die
                    "Specify assembly option (with --assembly=\"GRCh38\") for this BAM submission batch.\n"
                    unless ( defined($assembly) );

            }
            elsif ( $file_format eq 'vcf' ) {
                die
                    "Specify assembly option (with --assembly=\"GRCh38\") for this VCF submission batch.\n"
                    unless ( defined($assembly) );
            }
            else {
                die "File is not FASTQ/BAM/VCF. Aborting.\n";
            }
        }
        my $assay_term_name;
        my $library_size_range;
        if ( $encID_type eq 'lib' ) {

            #foreach my $object (@{$$objects_tree{'@graph'}}){
            foreach my $id ( keys %{$objects_tree} ) {

                #print STDERR "$id\n";
                my $is_replicate = 0;
                foreach my $i ( @{ $$objects_tree{$id}{'@type'} } ) {
                    if ( $i eq 'Replicate' ) {
                        $is_replicate = 1;
                        last;
                    }
                }
                if ( $is_replicate == 1 ) {

                  #get current library ID , sth like "/libraries/ENCLB511FVM/"
                    if ( exists $$objects_tree{$id}{'library'} ) {
                        my $currentLibraryWeirdId
                            = $$objects_tree{$id}{'library'};

               #print STDERR "currentLibraryWeirdId $currentLibraryWeirdId\n";
                        if (exists(
                                $$objects_tree{$currentLibraryWeirdId}
                                    {'accession'}
                            )
                            && $$objects_tree{$currentLibraryWeirdId}
                            {'accession'} eq $encID
                            )
                        {
                            # print STDERR Dumper $$objects_tree{$id};
                            $replicate_number = $$objects_tree{$id}
                                {'biological_replicate_number'};
                            if ( exists( $$objects_tree{$id}{'experiment'} ) )
                            {
                                $$objects_tree{$id}{'experiment'}
                                    =~ /\/experiments\/(\S+)\//;
                                $dataset = $1;
                            }
                            else {
                                warn
                                    "No 'experiment' property found for object $$objects_tree{$id}{'accession'} (library '$encID'). Skipped\n";
                                next;
                            }
                            $replicate_uuid = $$objects_tree{$id}{'uuid'};

                            $library_size_range
                                = $$objects_tree{$encID}{'size_range'};
                            last;
                        }
                    }
                }
            }
        }
        elsif ( $encID_type eq 'exp' )
        { # ENCSR is already known (i.e. it's in the filename). Only check that it does exist in DB
            warn "encID type is $encID_type. Setting rep number to 1.\n";
            $replicate_number=1;
            if ( exists $$objects_tree{$encID} ) {
                $dataset = $encID;
            }
            else {
                warn "$encID not found in metadata DB. Skipped\n";
                next;
            }
        }
        else {
            die;
        }
        unless ( defined $dataset ) {
            warn
                "No dataset found in collection for $filename (ENCID: $encID). Skipped (no JSON file created).\n";
            next;
        }

        foreach my $id ( keys %{$objects_tree} ) {
            my $is_experiment = 0;
            foreach my $i ( @{ $$objects_tree{$id}{'@type'} } ) {
                if ( $i eq 'Experiment' ) {
                    $is_experiment = 1;
                    last;
                }
            }
            if ( $is_experiment == 1 ) {
                if ( exists( $$objects_tree{$id}{'accession'} )
                    && $$objects_tree{$id}{'accession'} eq $dataset )
                {
                    $assay_term_name = $$objects_tree{$id}{'assay_term_name'};

# now fetch "experiment" in the "possible_controls" array, if available. that's for rampage data, in which case the corresponding RNASeq experiment is the possible_control. Once retrieved the RNAseq experiment, fetch replicate matching the rampage one, and put its FASTQs in the "controlled_by" (array) file property
                    if ( exists( $$objects_tree{$id}{'possible_controls'} ) )
                    {
                        foreach my $possible_control (
                            @{ $$objects_tree{$id}{'possible_controls'} } )
                        {
                            print STDERR
                                "\tpossible_control found: $possible_control\n";
                            my $possible_control_is_experiment = 0;
                            foreach my $i (
                                @{  $$objects_tree{$possible_control}{'@type'}
                                }
                                )
                            {
                                if ( $i eq 'Experiment' ) {
                                    $possible_control_is_experiment = 1;
                                    last;
                                }
                            }
                            if ( $possible_control_is_experiment == 1 ) {

                                # get matching replicate
                                foreach my $repInPossibleControlExp (
                                    @{  $$objects_tree{$possible_control}
                                            {'replicates'}
                                    }
                                    )
                                {
#print STDERR "\trepInPossibleControlExp: $repInPossibleControlExp\n";
#print STDERR "repInPossibleControlExp uuid: $$repInPossibleControlExp{'uuid'}";
                                    if ($$objects_tree{
                                            $repInPossibleControlExp}
                                        {'biological_replicate_number'}
                                        == $replicate_number )
                                    {
                                        print STDERR
                                            "\tMatched control rep: $repInPossibleControlExp\n";

                                        # get corresponding files
                                        my $found_controlled_by_files = 0;
                                        foreach
                                            my $id2 ( keys %{$objects_tree} )
                                        {
                                            my $is_file = 0;
                                            foreach my $i (
                                                @{  $$objects_tree{$id2}
                                                        {'@type'}
                                                }
                                                )
                                            {
                                                if ( $i eq 'File' ) {
                                                    $is_file = 1;
                                                    last;
                                                }
                                            }
                                            if ( $is_file == 1 ) {
                                                if (exists(
                                                        $$objects_tree{$id2}
                                                            {'replicate'}
                                                    )
                                                    && $$objects_tree{$id2}
                                                    {'replicate'} eq
                                                    $repInPossibleControlExp
                                                    && $$objects_tree{$id2}
                                                    {'output_type'} eq 'reads'
                                                    && $$objects_tree{$id2}
                                                    {'file_format'} eq 'fastq'
                                                    && $$objects_tree{$id2}
                                                    {'paired_end'}
                                                    == $paired_end
                                                    )
                                                {
                                                    $found_controlled_by_files
                                                        = 1;
                                                    $controlled_by{
                                                        $$objects_tree{$id2}
                                                            {'accession'}
                                                    } = 1;

               #print STDERR "found file $$objects_tree{$id2}{'accession'}\n";
                                                }
                                            }
                                        }
                                        if ( $found_controlled_by_files == 0 )
                                        {
                                            warn
                                                "\n\n\t####################################### WARNING: No controlled_by files in collection.\n\n";
                                        }
                                        last;
                                    }
                                }
                            }
                        }
                    }
                    last;
                }

            }
        }

        my @fileDerivedFrom;
        if ( $file_format ne 'fastq' )
        { # fetch corresponding FASTQs (for BAMs) or BAMs (for VCFs) the files are derived from
            @fileDerivedFrom = fetchFileDerivedFrom( $encID, $file_format );
            if (@fileDerivedFrom) {
                @{ $file_metadata{$filename}{'derived_from'} }
                    = @fileDerivedFrom;
            }
            else {
                if ( $file_format ne 'fastq' ) {
                    warn
                        "No derived_from files found in collection for $filename (ENCID: $encID). Skipped (no JSON file created).\n";
                    next;
                }
            }
        }

        foreach my $controlled_by_file ( keys %controlled_by ) {
            push(
                @{ $file_metadata{$filename}{'controlled_by'} },
                $controlled_by_file
            );
        }
        my $spikeins_file = "ENCFF001RTP";
        print STDERR "\t$assay_term_name,";
        if ( defined $library_size_range ) {
            print STDERR " $library_size_range. ";
        }

        #set controlled_by spike_ins if long RNA-seq
        if (   $assay_term_name eq "RNA-seq"
            && defined($library_size_range)
            && $library_size_range eq ">200" )
        {
            push(
                @{ $file_metadata{$filename}{'controlled_by'} },
                $spikeins_file
            );
            print STDERR "controlled_by: $spikeins_file\n";
        }
        else {
            print STDERR "\n";
        }
        if ( defined($replicate_uuid) ) {
            $file_metadata{$filename}{'replicate'}
                = "/replicates/$replicate_uuid";
        }
        $file_metadata{$filename}{'file_format'} = $file_format;
        $file_metadata{$filename}{'output_type'} = $output_type;
        if ( defined($read_length) ) {
            print STDERR "\treadlength is defined: $read_length\n";
            $file_metadata{$filename}{'read_length'} = $read_length;
            $file_metadata{$filename}{'read_length'}
                += 0;    # make sure type is int and not string in ouput JSON
        }
        else {
            print STDERR "\treadlength is UNDEFINED\n";

        }
        $file_metadata{$filename}{'submitted_file_name'} = $filename;
        $file_metadata{$filename}{'paired_end'}          = $paired_end
            if ( defined $paired_end );
        $file_metadata{$filename}{'dataset'}  = $dataset;
        $file_metadata{$filename}{'run_type'} = $run_type
            if ( defined $run_type );
        $file_metadata{$filename}{'md5sum'}    = $md5sum;
        $file_metadata{$filename}{'file_size'} = $file_size;
        if ( defined($seqPlatform) ) {
            print STDERR "\tPlatform is: $seqPlatform\n";
            $file_metadata{$filename}{'platform'} = $seqPlatform;

        }
        else {
            print STDERR "\tPlatform is UNDEFINED\n";
        }
        if ( defined($assembly) ) {
            print STDERR "\tAssembly is: $assembly\n";
            $file_metadata{$filename}{'assembly'} = $assembly;

        }

        $file_metadata{$filename}{'lab'}   = "thomas-gingeras";
        $file_metadata{$filename}{'award'} = "U54HG007004";

        if ( $assay_term_name eq 'RAMPAGE' ) {
            push(
                @{  $file_metadata{$filename}{'file_format_specifications'}
                },
                '28a9fcd3-1a6a-4c88-9e30-bd4e43afce42'
            );    # RAMPAGE_Library_Structure_2.pdf
        }

        my $file_basename = basename($filename);
        my $file_alias    = "roderic-guigo:$file_basename"
            ;     # "aliases" value don't support slashes as of march 2015
        push( @{ $file_metadata{$filename}{'aliases'} }, $file_alias );

        if ($paired_end) {    #set paired_with property if read2
            $file_alias =~ /(.*)([1-2])(\.fastq\.gz)$/;
            my $pre = $1;
            my $suf = $3;
            die
                "'paired_end' property mismatch:\n\tfrom filename: $paired_end\n\tfrom file_alias: $2 (file_basename: $file_basename)\nDIED.\n"
                unless ( $paired_end eq $2 );
            if ( $paired_end eq '1' ) {

            }
            elsif ( $paired_end eq '2' ) {
                $file_metadata{$filename}{'paired_with'} = $pre . "1" . $suf;
            }
            else {
                die;
            }
        }
        if ( defined($barcode) && $barcode ne '' )
        {    # i.e. the barcode sequence is specified in the fastq read ID
            ${ $file_metadata{$filename}{'flowcell_details'} }[0]{'machine'}
                = $unique_instrument_name;
            ${ $file_metadata{$filename}{'flowcell_details'} }[0]{'flowcell'}
                = $flowcell_id;
            ${ $file_metadata{$filename}{'flowcell_details'} }[0]{'lane'}
                = $flowcell_lane;
            ${ $file_metadata{$filename}{'flowcell_details'} }[0]{'barcode'}
                = $barcode;
        }
        elsif ( exists $enclbToBarcodeSet{$encID} ) {
            foreach my $bcode ( @{ $enclbToBarcodeSet{$encID} } ) {
                my %tmpFlowCellDetails = ();
                $tmpFlowCellDetails{'barcode_position'} = 1;
                $tmpFlowCellDetails{'flowcell'}         = $flowcell_id;
                $tmpFlowCellDetails{'lane'}             = $flowcell_lane;
                $tmpFlowCellDetails{'barcode'}          = $bcode;
                $tmpFlowCellDetails{'barcode_in_read'} = "1"; # must be string
                $tmpFlowCellDetails{'machine'} = $unique_instrument_name;
                push(
                    @{ $file_metadata{$filename}{'flowcell_details'} },
                    \%tmpFlowCellDetails
                );
            }
        }
        else {
            if ( $file_format eq 'fastq' ) {
                die "no barcode info found for file $filename. Exiting.\n";
            }
        }
        print STDERR " Done.\n";
    }
    else {
        warn
            "\tSKIPPED $filename: Malformed filename, couldn't read metadata.\n";
    }
}

#  print Dumper \%file_metadata;
#print to_json(\%file_metadata);
print STDERR "Creating JSON files...";
foreach my $file ( keys %file_metadata ) {
    my $outJson = $file . ".json";
    open OUTJSON, ">$outJson" or die $!;
    print OUTJSON to_json( \%{ $file_metadata{$file} } ) . "\n";
}
print STDERR " Done.\n";

sub fetchFileDerivedFrom {
    my $encID       = $_[0];
    my $file_format = $_[1];
    my $fileTypeDerivedFrom;
    my @fileDerivedFromReturn = ();
    if ( $file_format eq 'bam' ) {
        $fileTypeDerivedFrom = 'fastq';
    }
    elsif ( $file_format eq 'vcf' ) {
        $fileTypeDerivedFrom = 'bam';
    }
    else {
        die;
    }
    if ( exists $$objects_tree{$encID} ) {
        if ( exists( $$objects_tree{$encID}{'original_files'} ) ) {

            #print STDERR Dumper $$objects_tree{$encID}{'files'};
            foreach my $f ( @{ $$objects_tree{$encID}{'original_files'} } ) {

                #print STDERR "$f\n";
                if ( $$objects_tree{$f}{'file_format'} eq
                    $fileTypeDerivedFrom )
                {
                    #print STDERR "$f match\n";
                    push( @fileDerivedFromReturn, $f );
                }
            }
        }
    }
    return @fileDerivedFromReturn;

}
