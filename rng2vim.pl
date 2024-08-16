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

# XML 1.1 character entity references:
use constant XML_ENTITIES   => qw( lt gt amp apos quot );

# HTML 4.01 and XHTML 1.0 character entity references:
use constant XHMTL_ENTITIES => qw( aacute Aacute acirc Acirc acute aelig AElig
agrave Agrave alefsym alpha Alpha amp and ang apos aring Aring asymp atilde
Atilde auml Auml bdquo beta Beta brvbar bull cap ccedil Ccedil cedil cent
chi Chi circ clubs cong copy crarr cup curren dagger Dagger darr dArr deg
delta Delta diams divide eacute Eacute ecirc Ecirc egrave Egrave empty emsp
ensp epsilon Epsilon equiv eta Eta eth ETH euml Euml euro exist fnof forall
frac12 frac14 frac34 frasl gamma Gamma ge gt harr hArr hearts hellip iacute
Iacute icirc Icirc iexcl igrave Igrave image infin int iota Iota iquest
isin iuml Iuml kappa Kappa lambda Lambda lang laquo larr lArr lceil ldquo
le lfloor lowast loz lrm lsaquo lsquo lt macr mdash micro middot minus mu
Mu nabla nbsp ndash ne ni not notin nsub ntilde Ntilde nu Nu oacute Oacute
ocirc Ocirc oelig OElig ograve Ograve oline omega Omega omicron Omicron
oplus or ordf ordm oslash Oslash otilde Otilde otimes ouml Ouml para part
permil perp phi Phi pi Pi piv plusmn pound prime Prime prod prop psi Psi
quot radic rang raquo rarr rArr rceil rdquo real reg rfloor rho Rho rlm
rsaquo rsquo sbquo scaron Scaron sdot sect shy sigma Sigma sigmaf sim
spades sub sube sum sup sup1 sup2 sup3 supe szlig tau Tau there4 theta
Theta thetasym thinsp thorn THORN tilde times trade uacute Uacute uarr uArr
ucirc Ucirc ugrave Ugrave uml upsih upsilon Upsilon uuml Uuml weierp xi Xi
yacute Yacute yen yuml Yuml zeta Zeta zwj zwnj );

# Command line options:
our $option_xhtml_entities = 0;
our $option_interactive    = 0;
our $option_author         = '';
our $option_language       = '';
our $option_maintainer     = '';
our $option_url            = '';

# A cache:
our $cache                 = {};

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

# Display usage information.
#
# Usage: display_usage
sub display_usage {
  # Get the script name:
  my $name = NAME;

  # Display usage information:
  print << "END_USAGE";
Usage: $name [OPTION...] SCHEMA NAME

  -a, --author NAME        specify the XML data file author
  -l, --language LANGUAGE  specify the XML data file language
  -m, --maintainer NAME    specify the XML data file maintainer
  -u, --url URL            specify the XML data file URL
  -x, --xhtml-entities     use XHTML 1.0 character entity references
  -i, --interactive        prompt before overwriting an existing file
  -h, --help               display usage information and exit
  -v, --version            display version information and exit
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

  # Check if the definition is already known:
  if (my $node = $cache->{$name}) {
    # Return the node:
    return $node;
  }

  # Find the node with the definition of the given named pattern:
  my ($node) = $document->findnodes("//*[name()='define' and \@name='$name']");

  # Add the node to the cache:
  $cache->{$name} = $node;

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

# Return a list containing supported root elements.
#
# Usage: get_root_elements <document>
sub get_root_elements {
  # Get function arguments:
  my $document = shift || die 'Invalid number of arguments';

  # Find the node with root element definitions:
  my ($node) = $document->findnodes("/*[name()='grammar']//*[name()='start']");

  # Find supported root elements:
  my @elements = get_children($document, $node);

  # Return the result:
  return @elements;
}

# Return a string with the date in the YYYY-MM-DD format.
#
# Usage: date_to_string [<unix_time>]
sub date_to_string {
  # Get function arguments:
  my $unix_time = shift || time;

  # Convert the Unix time entry to a human-readable format:
  my @time = localtime($unix_time);
  return sprintf("%d-%02d-%02d", ($time[5] + 1900), ++$time[4], $time[3]);
}

# Convert a RELAX NG schema to an XML data file for Vim.
#
# Usage: rng_to_vim <schema> <name>
sub rng_to_vim {
  # Get function arguments:
  my $schema = shift || die 'Invalid number of arguments';
  my $name   = shift || die 'Invalid number of arguments';

  # Compose the output file name:
  my $file   = "$name.vim";

  # When in interactive mode, check if the file already exists:
  if ($option_interactive && -e $file) {
    # Display the prompt:
    print "Rewrite the file named `$file'? ";

    # Terminate the script if the answer is not positive:
    exit 0 unless (readline(*STDIN) =~ /^(y|yes)$/i);
  }

  # Parse the XML schema:
  my $parser   = XML::LibXML->new(clean_namespaces => 1, no_defdtd => 1, expand_xinclude => 1);
  my $document = $parser->parse_file($schema);

  # Get a list of defined XML elements:
  my %elements = get_elements($document);
  my @root     = get_root_elements($document);

  # Open the output file for writing:
  unless (open(FOUT, ">$file")) {
    # Report an error:
    display_error("Unable to open the $file file for writing.", 13);
  }

  # Print the XML data file header:
  print FOUT "\" Vim XML data file\n";
  print FOUT "\" Language:    $option_language\n"   if ($option_language);
  print FOUT "\" Author:      $option_author\n"     if ($option_author);
  print FOUT "\" Maintainer:  $option_maintainer\n" if ($option_maintainer);
  print FOUT "\" URL:         $option_url\n"        if ($option_url);
  print FOUT "\" Last Change: ", date_to_string(), "\n";

  # Print the XML data file start:
  print FOUT "\nlet g:xmldata_$name = {\n";

  # Print the list of entity references:
  print FOUT "\\ 'vimxmlentities': [", join(', ', map { "'$_'" } ($option_xhtml_entities) ? XHMTL_ENTITIES : XML_ENTITIES), "],\n";

  # Print the list of root elements:
  print FOUT "\\ 'vimxmlroot': [", join(', ', map { "'$_'" } sort @root ),"],\n";

  # Print element definitions:
  while (my ($element, $property) = each %elements) {
    # Get supported child elements and attributes:
    my @children = @{$property->[0]};
    my %attributes = %{$property->[1]};

    # Print the element definition:
    print FOUT "\\ '$element': [\n";
    print FOUT "\\ [", join(', ', map { "'$_'" } sort @children), "],\n";
    print FOUT "\\ {", join(', ', map { "'$_': [" . join(', ', map { "'$_'" } sort @{$attributes{$_}}) . "]" } sort keys %attributes), "}\n";
    print FOUT "\\ ],\n";
  }

  # Print the XML data file end:
  print FOUT "\\ }\n";

  # Close the file:
  close(FOUT);
}

# Configure the option parser:
Getopt::Long::Configure('no_auto_abbrev', 'no_ignore_case', 'bundling');

# Process the command line options:
GetOptions(
  'help|h'           => sub { display_usage();   exit 0;  },
  'version|v'        => sub { display_version(); exit 0;  },
  'xhtml-entities|x' => sub { $option_xhtml_entities = 1; },
  'interactive|i'    => sub { $option_interactive    = 1; },
  'author|a=s'       => sub { $option_author         = $_[1]; },
  'language|l=s'     => sub { $option_language       = $_[1]; },
  'maintainer|m=s'   => sub { $option_maintainer     = $_[1]; },
  'url|u=s'          => sub { $option_url            = $_[1]; },
);

# Verify the number of command line arguments:
if (scalar(@ARGV) != 2) {
  # Report an error:
  display_error("Invalid number of arguments.\n" .
                "Try \`" . NAME . " --help' for more information.", 22);
}

# Convert a RELAX NG schema to an XML data file for Vim:
rng_to_vim($ARGV[0], $ARGV[1]);

# Terminate the script:
exit 0;
