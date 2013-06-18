# A makefile for rng2vim
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

# General information:
NAME    = rng2vim
VERSION = 0.1.0

# General settings; change the shell or the path to the install executable:
SHELL   = /bin/sh
INSTALL = /usr/bin/install -c
POD2MAN = /usr/bin/pod2man
SRCS    = rng2vim.pl
MANS    = rng2vim.1
DOCS    = AUTHORS COPYING README.markdown

# Installation directories;  change these directories  to suite your needs:
prefix  = /usr/local
bindir  = $(prefix)/bin
mandir  = $(prefix)/share/man/man1
docdir  = $(prefix)/share/doc/$(NAME)-$(VERSION)

# The following are the make rules;  please, do not edit these rules unless
# you really know what you are doing:
.PHONY: all
all: $(MANS)

.PHONY: install
install: $(SRCS) $(MANS) $(DOCS)
	@echo "Copying executables..."
	$(INSTALL) -d $(bindir)
	$(INSTALL) -m 755 rng2vim.pl $(bindir)/rng2vim
	@echo "Copying manual pages..."
	$(INSTALL) -d $(mandir)
	$(INSTALL) -m 644 rng2vim.1 $(mandir)
	@echo "Copying documentation..."
	$(INSTALL) -d $(docdir)
	$(INSTALL) -m 644 AUTHORS $(docdir)
	$(INSTALL) -m 644 COPYING $(docdir)
	$(INSTALL) -m 644 README.markdown $(docdir)
	-$(INSTALL) -m 644 ChangeLog $(docdir)

.PHONY: uninstall
uninstall:
	@echo "Removing executables..."
	-rm -f $(bindir)/rng2vim
	-rmdir $(bindir)
	@echo "Removing manual pages..."
	-rm -f $(mandir)/rng2vim.1
	-rmdir $(mandir)
	@echo "Removing documentation..."
	-rm -f $(docdir)/AUTHORS
	-rm -f $(docdir)/COPYING
	-rm -f $(docdir)/README.markdown
	-rm -f $(docdir)/ChangeLog
	-rmdir $(docdir)

.PHONY: clean
clean:
	-rm -f $(MANS)

%.1: %.pod
	$(POD2MAN) --section=1 --release="$(VERSION)" $^ $@

