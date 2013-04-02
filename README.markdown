## Name

rng2vim — convert a RELAX NG schema to an XML data file for Vim

## Synopsis

    rng2vim [-x] [-a NAME] [-l LANGUAGE] [-m NAME] [-u URL] SCHEMA NAME

## Description

The **rng2vim** script provides an easy way to generate an XML data file for Vim's omni completion from a RELAX NG schema. It accepts a path or a link to the RELAX NG schema file and the name of the XML dialect as the command line arguments, and writes the contents of the XML data file to standard output. The **rng2vim** script requires a working installation of Perl and the XML::LibXML module to function.

For a detailed description of omni completion and an explanation of how to use it, refer to the official [Vim Documentation](http://vimdoc.sourceforge.net/htmldoc/insert.html#ft-xml-omni). For a sample output, see my repositories for [DocBook](https://github.com/jhradilek/vim-docbk), [Mallard](https://github.com/jhradilek/vim-mallard), and [RELAX NG](https://github.com/jhradilek/vim-rng).

## Options

* **-a** *name*, **--author** *name* — Use *name* as the name of the author in the XML data file header.
* **-l** *language*, **--language** *language* — Use *language* as the language in the XML data file header.
* **-m** *name*, **--maintainer** *name* — Use *name* as the name of the maintainer in the XML data file header.
* **-u** *url*, **--url** *url* — Use *url* as the URL in the XML data file header.
* **-x**, **--xhtml-entities** — Use character entity references documented in the XHTML 1.0 specification instead of those defined in the XML 1.1 standard.
* **-h**, **--help** — Display usage information and immediately terminate the script.
* **-v**, **--version** — Display version information and immediately terminate the script.

## Examples

To generate an XML data file from the RELAX NG schema for the RELAX NG schema language that is located online at http://relaxng.org/relaxng.rng, type the following at a shell prompt:

    rng2vim http://relaxng.org/relaxng.rng relaxng10 > relaxng10.vim

To generate an XML data file from the RELAX NG schema for the Mallard 1.0 markup language that is located in the current working directory, type:

    rng2vim mallard-1.0.rng mallard10 > mallard10.vim

To generate this data file with support for all 253 character entity references that are documented in the XHMTL 1.0 specification, use the following command:

    rng2vim -x mallard-1.0.rng mallard10 > mallard10.vim

## Copyright

Copyright © 2013 Jaromir Hradilek

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
