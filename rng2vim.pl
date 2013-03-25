#!/usr/bin/env perl

# rng2vim - converts a RELAX NG schema to an XML omni completion data file
# Copyright (C) 2013 Jaromir Hradilek

# This program is  free software:  you can redistribute it and/or modify it
# under  the terms  of the  GNU General Public License  as published by the
# Free Software Foundation, version 3 of the License.
#
# This program  is  distributed  in the hope  that it will  be useful,  but
# WITHOUT  ANY WARRANTY;  without  even the implied  warranty of MERCHANTA-
# BILITY  or  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
# License for more details.
#
# You should have received a copy of the  GNU General Public License  along
# with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use XML::LibXML;

# General information about the script:
use constant NAME    => basename($0, '.pl');
use constant VERSION => '0.1.0';

# Reconfigure the __WARN__ signal handler:
$SIG{__WARN__} = sub {
  print STDERR NAME . ": " . (shift);
};

# Display an error message and terminate the script.
#
# Usage: display_error <message> [<exit_status>]
sub display_error {
  # Get function arguments and assign their default values:
  my $error_message = shift || die 'Invalid number of arguments';
  my $exit_status   = shift || 1;

  # Display the error message:
  print STDERR NAME . ": $error_message\n";

  # Terminate the script:
  exit $exit_status;
}

# Display a warning message.
#
# Usage: display_warning <message>
sub display_warning {
  # Get function arguments:
  my $warning_message = shift || die 'Invalid number of arguments';

  # Display the warning:
  print STDERR "$warning_message\n";
}

# Display usage information.
#
# Usage: display_usage
sub display_usage {
  # Get the script name:
  my $name = NAME;

  # Display usage information:
  print << "END_USAGE";
Usage: $name FILE

  -h, --help        display usage information and exit
  -v, --version     display version information and exit
END_USAGE
}

# Display version information.
#
# Usage: display_version
sub display_version {
  # Display version information:
  print STDOUT NAME . " " . VERSION . "\n";
}

# Configure the option parser:
Getopt::Long::Configure('no_auto_abbrev', 'no_ignore_case', 'bundling');

# Process the command line options:
GetOptions(
  'help|h'    => sub { display_usage();   exit 0; },
  'version|v' => sub { display_version(); exit 0; },
);

# Verify the number of command line arguments:
display_error("Invalid number of arguments.", 22) if (scalar(@ARGV) == 0);

# Terminate the script:
exit 0;
