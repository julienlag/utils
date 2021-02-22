#!/usr/local/bin/perl

use strict ;

use lib "/users/rg/colin/workspace" ; 

use EncodeUtils::DbiConnection ; 

# connect to the db
my $dbh = DbiConnection->get_dbh_static('monstre1') or die "Problem creating db connection\n" ;


## prepare and execute the query

my $sql=<<SQL; 
SELECT 
	pe.expt_id as expt_id,	
	concat(t.internal_name , "_" , r.internal_name , "_" , 	c.internal_name , "_" , l.internal_name , "_1_1_hg18.bed") as filename, 
	num_features , 
	nucleotide_coverage, 
	number_projected_features,
	prop_exonic_projected_features,  
	prop_intronic_projected_features,
	prop_intergenic_projected_features,
	identifier 

FROM	proposed_experiments pe,
	expt_stats es,
	technology t,  
	rna_type r ,  
	cell_type c ,  
	localization l	
WHERE es.expt_id = pe.expt_id
AND pe.technology_id = t.technology_id   
AND pe.rna_type_id = r.rna_type_id   
AND pe.cell_type_id = c.cell_type_id   
AND pe.localization_id = l.localization_id 
SQL

my $statement_handle = $dbh->prepare($sql) or die "Problem preparing query" . $dbh->errstr ;
$statement_handle->execute() or die "Problem executing query" . $dbh->errstr;  

## go through results from db
while(my $hashref = $statement_handle->fetchrow_hashref()){

	## use the names in the SELECT clause as teh keys of the hash reference 
	print "expt_id: " . $hashref->{expt_id} . "\t" .  $hashref->{filename} . "\t" . $hashref->{num_features} . " ....etc\n";  
}


