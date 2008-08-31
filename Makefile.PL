#!/usr/bin/perl

# Copyright 2007, 2008 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Glib::Ex::ConnectProperties',
   ABSTRACT     => 'Link properties between objects.',
   VERSION_FROM => 'lib/Glib/Ex/ConnectProperties.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   PREREQ_PM    => {
                    # any version should be ok
                    'Glib' => 0,

                    # actually Glib requires perl 5.8, which has
                    # Scalar::Util builtin already
                    'Scalar::Util' => 0,
                   },

   clean        => { FILES => "ConnectProperties.html" },
  );




sub MY::postamble {
  return <<'MAKE_FRAG';

lint:
	perl -MO=Lint lib/Glib/Ex/ConnectProperties.pm t/*.t
	podchecker lib/Glib/Ex/ConnectProperties.pm
	perlcritic --nocolor -1 lib/Glib/Ex/ConnectProperties.pm t/*.t

myman:
	mv MANIFEST MANIFEST.old
	touch SIGNATURE
	(make manifest 2>&1; diff -u MANIFEST.old MANIFEST) |less

ConnectProperties.html: lib/Glib/Ex/ConnectProperties.pm Makefile
	-perl -MPod::Simple::HTML -e Pod::Simple::HTML::go \
	  lib/Glib/Ex/ConnectProperties.pm \
	| sed 's!http://search.cpan.org/perldoc?Glib%3A%3A\([^"]*\)!http://gtk2-perl.sourceforge.net/doc/pod/Glib/\1.html!' \
	  >ConnectProperties.html

# find files in the dist with mod times this year, but without this year in
# the copyright line
copyright-years-check:
	year=`date +%Y`; \
	tar tvfz Glib-Ex-ConnectProperties-$(VERSION).tar.gz \
	| grep $$year- \
	| sed 's:^.*Glib-Ex-ConnectProperties-$(VERSION)/::' \
	| (result=0; \
	  while read i; do \
	    case $$i in \
	      '' | */ | *.gmo \
	      | debian/changelog | debian/compat | debian/control \
	      | SIGNATURE | META.yml) \
	      continue ;; \
	    esac; \
	    if test -e "$(srcdir)/$$i"; then f="$(srcdir)/$$i"; \
	    else f="$$i"; fi; \
	    if ! grep -q "Copyright.*$$year" $$f; then \
	      echo "$$i:1: this file"; \
	      grep Copyright $$f; \
	      result=1; \
	    fi; \
	  done; \
	  exit $$result)

debug-constants-check:
	if egrep -n 'DEBUG => [^0]' $(TO_INST_PM); then exit 1; else exit 0; fi

diff-prev:
	rm -rf diff.tmp
	mkdir diff.tmp
	cd diff.tmp \
	&& tar xfz ../$(DISTNAME)-`expr $(VERSION) - 1`.tar.gz \
	&& tar xfz ../$(DISTNAME)-$(VERSION).tar.gz
	-cd diff.tmp; diff -ur $(DISTNAME)-`expr $(VERSION) - 1` \
	                       $(DISTNAME)-$(VERSION) >tree.diff
	-less diff.tmp/tree.diff
	rm -rf diff.tmp

MAKE_FRAG
}
