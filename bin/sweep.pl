#!/usr/bin/perl
use Getopt::Long;

#
# sweep.pl 
#
# Run multiple experiments while sweeping the value of one 
# parameter.
#

#---- Check Versions of Perl Modules -------------------------------------
my $module="Getopt::Long";
eval "require $module";
#printf( "%-20s: %s\n", $module, $module->VERSION ) unless ( $@ );

if ($module->VERSION<2.35) {
  print "\nError: Perl module 'Getopt::Long' version too old!\n";
  print "       Please install Getopt::Long version 2.35 or newer\n\n";
  exit;
}
#-------------------------------------------------------------------------

GetOptions ('config|c=s' => \$config,
	    'model|m=s' => \$model,
	    'sweep_param|p=s' => \$param,
            'sweep_values|s=s{,}' => \@sweep,
            'result_file|r=s' => \$result_file);

#------- Check Options ---------------------------------------------------

if (!defined($config)) {
  print "Error: You must define a valid configuration (--config)\n"; exit;
}
if (!defined($model)) {
  print "Error: You must define a simulation model (--model)\n"; exit;
}

if (!defined($param)) {
  print "Error: You must define a parameter to sweep (--sweep_param)\n"; exit;
}

if (!defined(@sweep)) {
  print "Error: You must define a list of values for the sweep parameter (--sweep_values)\n"; exit;
}

if (!defined($result_file)) {
  print "Error: You must specify a prefix for the name of each result file (--result_file)\n"; exit;
}

#------- Generate sweep.run file -----------------------------------------

print "**\n";
print "** Generating 'sweep.run-$result_file' command list\n";

open (SWEEPFILE, ">sweep.run-$result_file");

my $now = localtime time;

print SWEEPFILE "#/////////////////////////////////////////////////////\n";
print SWEEPFILE "# [Date $now]\n";
print SWEEPFILE "# Configuration string = $config\n";
print SWEEPFILE "# Model File           = $model\n";
print SWEEPFILE "# Sweep Parameter      = $param (values = ";
foreach $value (@sweep) {
  print SWEEPFILE "$value ";
}
print SWEEPFILE ")\n";

foreach $value (@sweep) {
  print SWEEPFILE "#/////////////////////////////////////////////////////\n\n";
  print SWEEPFILE "bin/makeconfig.pl $config --$param $value \n";
  print SWEEPFILE "bin/vt $model | tee $result_file$value \n\n";
}
print SWEEPFILE "#/////////////////////////////////////////////////////\n\n";

close(SWEEPFILE);

print "** Executing commands....\n";
print "**\n";
#----- RUN EXPERIMENTS ------
system ("chmod +x sweep.run-$result_file");
system ("./sweep.run-$result_file");
