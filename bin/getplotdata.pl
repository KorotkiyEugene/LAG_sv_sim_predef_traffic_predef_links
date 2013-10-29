#!/usr/bin/perl

#
# Simple script to extract injection rate and average latency
# figures from a set of simulation results.
#
# Robert Mullins, rdm34@cl.cam.ac.uk
#

use File::Basename;

sub usage {
  my $prog = basename($0);
  die <<EOF;

Netmaker - On-Chip Network Library

NAME
  $prog - Extract data from simulation results for plotting graphs

SYNOPSYS
  $prog PREFIX OUTPUTFILE

  PREFIX - Prefix of results files. Script will search each matching 
           simulation output file for injection rate/latency figures.

  OUTPUTFILE - Filename of output file (e.g. results.dat). 

EOF
}

@ARGV || usage;

$prefix=@ARGV[0];
$output=@ARGV[1];

$numArgs = $#ARGV + 1;
if ($numArgs < 2) {
  die "Error: You must specify both a PREFIX and OUTPUT FILE\n       Run without any arguments for more info.\n";
}

$dir = ".";
opendir(BIN, $dir) or die "Error: Can't open $dir: $!";

open RESULTFILE, "> $output" or die "Error: Can't open output file for writing: $!";
close (RESULTFILE);

$tmpfile = "/tmp/getplotdata_tmp";

open TMPFILE, "> $tmpfile" or die "Error: Can't open temporary file for writing: $!";

# For each file in current directory
while( defined ($file = readdir BIN) ) {

    # Does filename begin with prefix provided on command-line?
    $tomatch = substr($file, 0, length($prefix));
    if ($tomatch eq $prefix) {
      #
      # Open $file and get average latency figure and injection rate
      #
      open (RESULT, $file) or die "Error: Can't open $file: $!";
      $lat="Error";
      $rate="Error";
      while (<RESULT>) {
	# Look for "-- Average Latency = X.X (cycles)"
	if ($_=~/-- Average Latency = (\d+.\d+)/) {$lat=$1}
	# Look for "-- Injection Rate = X.X (flits/cycles/node)"
	if ($_=~/-- Injection Rate\s+= (\d+.\d+)/) {$rate=$1;}
      }
      close (RESULT);
      #
      # Check simulation ran to completion and reported stats.
      #
      if ($lat eq "Error") { die "Error: Result missing? in $file, stopping!\n";}
      if ($rate eq "Error") { die "Error: Result missing? in $file, stopping!\n";}

      print TMPFILE "$rate\t$lat\n";
    }

}
closedir(BIN);
close (TMPFILE);

#
# Sort temporary file and copy to output file
#
exec "sort $tmpfile > $output"
