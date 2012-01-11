#!/usr/bin/perl -s

##	add, remove or modify the delimiter in a hex string

use warnings;
use strict;

# define variables that will be used
# 
our $d;
our $c;
my @output;
my $input;
my $find;

# Define switch defaults
# -d switch is for delimeter; if -d is asserted without argument use ':' to delimit
if ( defined ( $d ) ) {
	if ( $d eq '1' ) { $d = ':'; }
	}

# -c is for count; if -c is not asserted default to a count of 2 (for WWNs)
# if -c is asserted without an argument the value of $c will be 1
$c ||= 2;

# set $input to the first (and hopefully only) argument supplied to the wwnuntil script
# this should be a hex string possibly delimeted with non-hex characters
$input = $ARGV[0];

# we are going to search for $c hex characters in a row
$find = "([a-fA-F0-9]{$c})";

# create an array @output which will be composed of all of the (regex) \1 substings in $input
@output = ($input =~ m/$find/g);

# if $d exists we want to delimit the substrings with $d
if ( defined( $d ) ) {

# print the join of $d, the delimeter, and @output, our (regex) \1 substrings
print join( $d, @output ) . "\n";
}

# if $d does not exist we don't want to delimit the output
# presumably to remove existing delimters from $input
else {

# print @output without delimiting it
print @output;
print "\n";
}
