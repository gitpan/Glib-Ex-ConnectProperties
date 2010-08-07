#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ConnectProperties.
#
# Gtk2-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ConnectProperties is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";

plan tests => 16;

require Glib::Ex::ConnectProperties;
MyTestHelpers::glib_gtk_versions();


## no critic (ProtectPrivateSubs)

#-----------------------------------------------------------------------------
# boxed -- Gtk2::Border
#
# It the past it might have been necessary to load up Gtk2::Entry for it to
# register Gtk2::Boxed.  That's no longer so, as of Gtk2 circa 1.202.

{ my $pspec = Glib::ParamSpec->boxed ('foo','foo','blurb',
                                      'Gtk2::Border', ['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec, undef, undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec, undef, {left=>1,right=>2,top=>3,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec, {left=>1,right=>2,top=>3,bottom=>4}, undef));

  ok (Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>2,top=>3,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>0,right=>2,top=>3,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>0,top=>3,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>2,top=>0,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>2,top=>3,bottom=>0}));
}

#-----------------------------------------------------------------------------
# enum Gtk2::Justification from Gtk2::Label

{ my $label = Gtk2::Label->new;
  my $pname = 'justify';
  my $pspec = $label->find_property ($pname)
    or die "Oops, Gtk2::Label doesn't have property '$pname'";
  diag "Gtk2::Label '$pname' pspec ",ref $pspec,
    ", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'right','right'));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'left','left'));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'right','left'));
}

#-----------------------------------------------------------------------------
# GdkColor - comparison by R/G/B contents using its 'equal' method

{ my $pspec = Glib::ParamSpec->boxed ('foo','foo','blurb',
                                      'Gtk2::Gdk::Color',['readable']);

  my $c1 = Gtk2::Gdk::Color->new (1,2,3);
  my $c1b = Gtk2::Gdk::Color->new (1,2,3);
  my $c2 = Gtk2::Gdk::Color->new (0,2,3);
  my $c3 = Gtk2::Gdk::Color->new (1,0,3);
  my $c4 = Gtk2::Gdk::Color->new (1,2,0);
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c1));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c1b));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c2));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c3));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c4));
}

exit 0;
