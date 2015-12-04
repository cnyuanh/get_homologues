#!/usr/bin/env perl
$|=1;

use strict;
use Getopt::Std;
use File::Basename;
use Benchmark;
use Cwd;
use FindBin '$Bin';
use lib "$Bin/lib";
use lib "$Bin/lib/bioperl-1.5.2_102/";
use marfil_homology;

my (%opts,$INP_dir,$INP_bpofile,$INP_i,$INP_j,$INP_evalue,$INP_noref);
my ($INP_pmatch,$INP_pi,$INP_nn_corr,$INP_forceredo,$INP_LSE,$INP_Pfam,$INP_use_short_sequence);
my ($INP_onlybesthit);

getopts('hs:d:b:i:j:E:S:C:N:f:l:D:n:B:', \%opts);

if(($opts{'h'})||(scalar(keys(%opts))==0))
{
  print   "\nusage: $0 [options]\n\n";
  print   "-h this message\n";
  print   "-d directory with input files\n";
  print   "-b .bpo file generated by sub blast_parse (marfil_homology.pm)\n";
  print   "-i taxon i\n";
  print   "-j taxon j\n";
  print   "-E max E-value\n";
  print   "-C min \%coverage in BLAST pairwise alignments\n";
  print   "-S min \%sequence identity in BLAST query/subj pairs\n";
  print   "-N min BLAST neighborhood correlation\n";
  print   "-D pfam_file generated in get_homologues.pl to enforce equal Pfam domain composition\n";
  print   "-B take only best hit\n";
  print   "-n noreference\n";
  print   "-l calculate lineage expansions\n";
  print   "-f force recalculation, otherwise might recover previous results\n";
  print   "-s use short sequence for coverage calculations\n\n";
  exit(0);
}

if(defined($opts{'d'})){  $INP_dir = $opts{'d'}; }
else{ die "# EXIT : need a -d directory\n"; }

if(defined($opts{'b'})){  $INP_bpofile = $opts{'b'}; }
else{ die "# EXIT : need a -b bpofile as input\n"; }

if(defined($opts{'i'})){  $INP_i = $opts{'i'}; }
else{ die "# EXIT : need parameter -i\n"; }

if(defined($opts{'j'})){  $INP_j = $opts{'j'}; }
else{ die "# EXIT : need parameter -j\n"; }

if(defined($opts{'E'})){  $INP_evalue = $opts{'E'}; }
else{ die "# EXIT : need parameter -E\n"; }

if(defined($opts{'C'})){ $INP_pmatch = $opts{'C'}; }
else{ die "# EXIT : need parameter -C\n"; }

if(defined($opts{'S'})){  $INP_pi = $opts{'S'}; }
else{ die "# EXIT : need parameter -S\n"; }

if(defined($opts{'N'})){ $INP_nn_corr = $opts{'N'}; }
else{ die "# EXIT : need parameter -N\n"; }

if(defined($opts{'f'})){ $INP_forceredo = $opts{'f'}; }
else{ die "# EXIT : need parameter -f\n"; }

if(defined($opts{'l'})){ $INP_LSE = $opts{'l'}; }
else{ die "# EXIT : need parameter -l\n"; }

if(defined($opts{'D'})){ $INP_Pfam = $opts{'D'}; }
else{ die "# EXIT : need parameter -D\n"; }

if(defined($opts{'n'})){ $INP_noref = $opts{'n'}; }
else{ die "# EXIT : need parameter -n\n"; }

if(defined($opts{'B'})){ $INP_onlybesthit = $opts{'B'}; }
else{ die "# EXIT : need parameter -B\n"; }

if(defined($opts{'s'})){ $INP_use_short_sequence = $opts{'s'}; }
else{ die "# EXIT : need parameter -s\n"; }

##########################################################################

## 1) create required data structures and get right file/dir names
constructDirectory($INP_dir);
$bpo_file = $INP_bpofile;
construct_taxa_indexes($bpo_file);

## 2) calculate LSEs (lineage specific expansions) using previous inparalogues
my($rhash_inparalogues_i) = makeInparalog(1,$INP_i,$INP_evalue,$INP_pi,$INP_pmatch,$INP_nn_corr,1,0,$INP_use_short_sequence);
my $LSE_i = cluster_lineage_expansions($rhash_inparalogues_i);

my($rhash_inparalogues_j) = makeInparalog(1,$INP_j,$INP_evalue,$INP_pi,$INP_pmatch,$INP_nn_corr,1,0,$INP_use_short_sequence);
my $LSE_j = cluster_lineage_expansions($rhash_inparalogues_j);

## 3) %gindex y %gindex2 are created here, while calling construct_indexes($bpo_file,($INP_i=>1,$INP_j=>1))
my($orth_table_ref) = makeOrtholog(1,$INP_i,$INP_j,$INP_onlybesthit,$INP_evalue,$INP_pi,$INP_pmatch,
  $INP_nn_corr,$INP_noref,$INP_Pfam,$INP_forceredo,$LSE_i,$LSE_j,$INP_use_short_sequence);

