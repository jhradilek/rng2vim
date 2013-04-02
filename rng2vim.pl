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

# RELAX NG elements to be analyzed:
use constant COMPOSITORS => qr/^(choice|div|grammar|group|interleave|list|mixed|oneOrMore|optional|zeroOrMore)$/;
use constant REFERENCES  => qr/^(parentRef|ref)$/;

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

# Return a node with the definition of a named pattern:
#
# Usage: find_definition <document> <name>
sub find_definition {
  # Get function arguments:
  my $document = shift || die 'Invalid number of arguments';
  my $name     = shift || die 'Invalid number of arguments';

  # Find the node with the definition of the given named pattern:
  my ($node) = $document->findnodes("//*[name()='define' and \@name='$name']");

  # Return the node:
  return $node;
}

# Return a hash containing allowed child elements, attributes, or attribute
# values.
#
# Usage: find_properties <document> <node> element|attribute|value
sub find_properties {
  # Get function arguments:
  my $document = shift || die 'Invalid number of arguments';
  my $parent   = shift || die 'Invalid number of arguments';
  my $type     = shift || die 'Invalid number of arguments';

  # Verify that the supplied type is supported:
  die 'Invalid argument' unless ($type =~ /^(attribute|element|value)$/);

  # Declare required variables:
  my %result = ();

  # Add child nodes to the queue:
  my @queue  = $parent->childNodes;

  # Process all nodes in the queue:
  while (my $node = shift @queue) {
    # Get the name of the currently processed node:
    my $node_name = $node->nodeName;

    # Check whether the node is of the required type:
    if ($node_name eq $type) {
      # Check if the node is an element:
      if ($type eq 'element') {
        # Get the name of the element:
        if (my $element_name = $node->getAttribute('name')) {
          # Add the element to the list of allowed children:
          $result{$element_name} = '';
        }
      }
      # Check if the node is an attribute:
      elsif ($type eq 'attribute') {
        # Get the name of the attribute:
        if (my $attribute_name = $node->getAttribute('name')) {
          my @values = get_values($document, $node);

          # Add the attribute to the list:
          $result{$attribute_name} = \@values;
        }
      }
      # Check if the node is a value:
      elsif ($type eq 'value') {
        # Get the actual value:
        my $value = $node->to_literal;

        # Add the value to the list:
        $result{$value} = '';
      }
    }
    # Check whether the node is a relevant compositor:
    elsif ($node_name =~ COMPOSITORS) {
      # Add child nodes to the queue:
      push(@queue, $node->childNodes);
    }
    # Check whether the node is a reference:
    elsif ($node_name =~ REFERENCES) {
      # Get the name of the referenced name pattern:
      my $reference_name = $node->getAttribute('name');

      # Locate the definition of the referenced name pattern:
      my $reference_target = find_definition($document, $reference_name);

      # Add child nodes to the queue:
      push(@queue, $reference_target->childNodes);
    }
  }

  # Return the result:
  return %result;
}

# Return a list containing supported attribute values.
#
# Usage: get_values <document> <node>
sub get_values {
  # Get function arguments:
  my $document = shift || die 'Invalid number of arguments';
  my $node     = shift || die 'Invalid number of arguments';

  # Find supported attribute values:
  my %temporary = find_properties($document, $node, 'value');

  # Return the result:
  return keys %temporary;
}

# Return a hash containing supported attributes and their possible values.
#
# Usage: get_attributes <document> <node>
sub get_attributes {
  # Get function arguments:
  my $document = shift || die 'Invalid number of arguments';
  my $node     = shift || die 'Invalid number of arguments';

  # Find allowed element attributes and return the result:
  return find_properties($document, $node, 'attribute');
}

# Return a list containing allowed child elements.
#
# Usage: get_children <document> <node>
sub get_children {
  # Get function arguments:
  my $document = shift || die 'Invalid number of arguments';
  my $node     = shift || die 'Invalid number of arguments';

  # Find allowed child elements:
  my %temporary = find_properties($document, $node, 'element');

  # Return the result:
  return keys %temporary;
}

# Return a hash containing  all available elements, their allowed children,
# supported attributes, and available attribute values.
#
# Usage: get_elements <document>
sub get_elements {
  # Get function arguments:
  my $document = shift || die 'Invalid number of arguments';

  # Declare required variables:
  my %result = ();

  # Find all element definitions:
  foreach my $element ($document->findnodes("//*[name()='element' and \@name]")) {
    # Get the name of the element:
    my $name = $element->getAttribute('name');

    # Get a list of supported child elements and attributes:
    my @children   = get_children($document, $element);
    my %attributes = get_attributes($document, $element);

    # Check if there already is an element of the same name:
    if (exists $result{$name}) {
      # Get the original list of supported child elements and attributes:
      my @element = @{$result{$name}};
      my @original_children   = @{$element[0]};
      my %original_attributes = %{$element[1]};

      # Update the list of supported child elements:
      @children = keys %{{ map { $_ => 1 } (@children, @original_children) }};

      # Process all attributes:
      while (my ($key, $values) = each %original_attributes) {
        # Check if there already is an attribute of the same name:
        if (exists $attributes{$key}) {
          # Update the list of supported attribute values:
          @$values = keys %{{ map { $_ => 1 } (@{$attributes{$key}}, @$values) }};
        }

        # Update the list of supported attributes:
        $attributes{$key} = $values;
      }
    }

    # Add the element definition to the list:
    $result{$name} = [ \@children, \%attributes ];
  }

  # Return the result:
  return %result;
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