#!/usr/bin/perl -pi

##Tool to mask IP addresses in a file.
#@USAGE ipMask.pl inputfile
#@ARGUMENT inputfile - a text file which will be scrubbed of IP addresses.

use warnings;
use strict;

# Create a variable to store the original unedited line (for later printing if a match is found)
my $origline;

# Look for the most obvious IPs (i.e. those which are seperated by blank space) and redact
if ( $origline = $_ and s/(?<=\b)(\d{1,3}\.){3}(\d{1,3})(?=\b)/xxx\.xxx\.xxx\.xxx/g ) {
# Print the file it was found in, the line number and the text of the original line
	print ( STDOUT "IP found in file: " . $ARGV . " Line:" . $. . " : " . $origline );
}

# Look for suspected IPs (i.e those that may be butted up against other words or delimeters
if ( m/(\d{1,3}\.){3}(\d{1,3})/g ) {
# Print the file it was found in, the line number and the text of the line
	print ( STDOUT "!!Possible IP found in file: " . $ARGV . " Line:" . $. . " : " . $_ );
}
