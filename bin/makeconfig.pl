#!/usr/bin/perl

#
# makeconfig.pl
#
# Part of Netmaker - On-Chip Network Library
#
#/////////////////////////////////////////////////
# Process a configuration file/ command-line 
# arguments and generate `defines and parameters 
# for type definitions and Verilog modules
# ////////////////////////////////////////////////
#
# July 2007/ April 2009
#
# Robert Mullins, rdm34@cl.cam.ac.uk
#

# February 2012
# Modified by Korotkyi Ievgen

# you'll need the 'perl-AppConfig' package if its not installed already on 
# your system.
#
# e.g.
# mkdir perl5; cd perl5
# wget http://www.cpan.org/modules/by-module/AppConfig/AppConfig-1.66.tar.gz
# gzip -d AppConfig-1.66.tar.gz
# tar -xvf AppConfig-1.66.tar
# export PERL5LIB=$NETMAKER_ROOT/perl5/AppConfig-1.66/lib
#

use AppConfig qw/:argcount/; 
use Math::Complex;
use File::Basename;
use POSIX qw(ceil floor);

sub usage {
  my $prog = basename($0);
  die <<EOF;

Netmaker - On-Chip Network Library

NAME
  $prog - Used to configure simulation and network parameters

SYNOPSIS
  $prog [-f PARAMETERFILE]... [--PARAMETERNAME PARAMETERVALUE]... 

DESCRIPTION

  Network and simulation parameters are specified using a configuration
  file and/or command-line arguments. '$prog' takes this 
  configuration information and creates the necessary SystemVerilog files 
  required during simulation/synthesis (parameters.v and defines.v).

  e.g. 
          $prog -f base.config --sim_injection_rate 0.1
  
  Read a baseline configuration and adjust the injection rate to be 0.1 
  flits/node/clock cycle.

  Any number of configuration files and command line arguments may be
  specified. If a parameter value is defined multiple times, its 
  final value is determined by the latest definition.

SEE ALSO 

  SWEEPING PARAMETERS AND RUNNING MULTIPLE SIMULATIONS
  ====================================================

  It is often necessary to sweep a range of values for a parameter
  requiring multiple simulations to be run. The simplest way to 
  achieve this is to use 'sweep.pl' instead of repeatedly 
  redefining parameters using '$prog'.

EOF
}

sub my_error {
  my $mess = shift;
  print "\n!!!!Error: ", $mess , "\n\n";
  die;
}

sub check1 {
  my $config = shift;
  my $d = $config->get("channel_data_width");
  my $r = $config->get("router_radix");
  my $x = ceil(logn($config->get("network_x"),2)); #X_addr_bits
  my $y = ceil(logn($config->get("network_y"),2)); #Y_addr_bits
  if ($d < $r + $x +$y + 2) 
  {
    my_error "Parameter \"channel_data_width\" must be greater or eq. than sum of \"router_radix\", ceil(logn(network_x,2)) and ceil(logn(network_y,2))" ;
  }
}



my $config = AppConfig->new();

$config->define(

# ------------------------------------------------------------------
# Define list of valid parameters
# ------------------------------------------------------------------

# `defines 
'debug' => { DEFAULT => 1},
'verbose' => { DEFAULT => 0},

#
# Local optimisations
#
'opt_meshxyturns' => {DEFAULT => 0},

#
# Simulation Parameters
#
'sim_warmup_packets' => {ARGCOUNT=>ARGCOUNT_ONE, DEFAULT => 1000},
'sim_measurement_packets' => {ARGCOUNT=>ARGCOUNT_ONE, DEFAULT => 10000},
'sim_packet_length' => {ARGCOUNT=>ARGCOUNT_ONE, DEFAULT => 4},

#
# Network and Link Parameters
#
'network_x' => {ARGCOUNT=>ARGCOUNT_ONE, DEFAULT => 8 },
'network_y' => {ARGCOUNT=>ARGCOUNT_ONE, DEFAULT => 8 },

'channel_data_width' => {ARGCOUNT => ARGCOUNT_ONE, DEFAULT => 64 },

#
# Basic Router Parameters
#

'router_num_pls' => {ARGCOUNT=>ARGCOUNT_ONE, DEFAULT => 4 },
'router_num_pls_on_entry' => {ARGCOUNT=>ARGCOUNT_ONE, DEFAULT => 1 },
'router_num_pls_on_exit' => {ARGCOUNT=>ARGCOUNT_ONE, DEFAULT => 1 },

'router_radix' => {ARGCOUNT=>ARGCOUNT_ONE, DEFAULT => 5 },
'router_buf_len' => {ARGCOUNT=>ARGCOUNT_ONE, DEFAULT => 4 },
'router_alloc_stages' => {ARGCOUNT=>ARGCOUNT_ONE, DEFAULT => 1 },

# ------------------------------------------------------------------
# Allow a file of parameters to be specified too
# ------------------------------------------------------------------
'file' => { ALIAS => "filelist|f",
	    ARGCOUNT => ARGCOUNT_LIST,
	    VALIDATE => sub
	    {
	      my $varname = shift @_;
	      my $value = shift @_;
	      if (!(-r $value)) { 
		die "File '$value' does not exist";
	      }
	      return (1);
	    },
	    ACTION => sub
	    {
	      shift @_;
	      my $varname = shift @_;
	      my $value = shift @_;
	      
	      print "## Parsing $value\n";
	      
	      $config->file($value);
	    }
	  },

);

@ARGV || usage;

print "## \n";
print "## Netmaker - Make Configuration \n";
print "## \n";

open (DEFINESFILE, ">defines.v");
open (PARAMSFILE, ">parameters.v");

$config->args();

my %varlist = $config->varlist('.*');

#
# Check validity of parameters
#

$config->get("file");

check1($config);

#
# Generate defines.v
# 
print DEFINESFILE "/********** defines.v **********/\n";
print DEFINESFILE "// `defines are only used to create type definitions (and in some local optimisations)\n";
print DEFINESFILE "// module parameters should always be used locally in\n";
print DEFINESFILE "// modules\n\n";
if ($config->get("opt_meshxyturns")) {
  print DEFINESFILE "`define OPT_MESHXYTURNS\n";
}
if ($config->get("debug")) {
  print DEFINESFILE "`define DEBUG\n";
}
if ($config->get("verbose")) {
  print DEFINESFILE "`define VERBOSE\n";
}



print DEFINESFILE "`define X_ADDR_BITS ".ceil(logn($config->get("network_x"),2))."\n";
print DEFINESFILE "`define Y_ADDR_BITS ".ceil(logn($config->get("network_y"),2))."\n";



close (DEFINESFILE);
#
# Generate parameters.v
#
print PARAMSFILE "/******* parameters.v **********/\n";
foreach my $varname (keys %varlist)
{
  if ($varname eq "file") {
  } else {
    print PARAMSFILE "parameter ", $varname, "=", $config->get($varname), ";\n";
  }
}
close (PARAMSFILE);

print "## Created 'defines.v' and 'parameters.v' \n";
print "## \n";
print "## WARNING: Be careful not to overwrite these files by running\n";
print "##          'makeconfig.pl' again before running your simulation.\n";
print "## \n";

