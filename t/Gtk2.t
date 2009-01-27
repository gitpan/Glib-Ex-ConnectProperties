#!/usr/bin/perl

# Copyright 2008, 2009 Kevin Ryde

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
use Glib::Ex::ConnectProperties;
use Test::More;

my $have_gtk2 = eval { require Gtk2 };
if (! $have_gtk2) {
  plan skip_all => "due to Gtk2 module not available -- $@";
}
plan tests => 23;

require Glib;
diag ("Perl-Glib version ",Glib->VERSION);
diag ("Compiled against Glib version ",
      Glib::MAJOR_VERSION(), ".",
      Glib::MINOR_VERSION(), ".",
      Glib::MICRO_VERSION(), ".");
diag ("Running on       Glib version ",
      Glib::major_version(), ".",
      Glib::minor_version(), ".",
      Glib::micro_version(), ".");
diag ("Perl-Gtk2 version ",Gtk2->VERSION);
diag ("Compiled against Gtk version ",
      Gtk2::MAJOR_VERSION(), ".",
      Gtk2::MINOR_VERSION(), ".",
      Gtk2::MICRO_VERSION(), ".");
diag ("Running on       Gtk version ",
      Gtk2::major_version(), ".",
      Gtk2::minor_version(), ".",
      Gtk2::micro_version(), ".");

## no critic (ProtectPrivateSubs)


#-----------------------------------------------------------------------------
# Gtk2::Border struct from Gtk2::Entry

{ my $entry = Gtk2::Entry->new;
  my $pname = 'inner-border';
  my $pspec = $entry->find_property ($pname)
    or die "Oops, Gtk2::Entry doesn't have property '$pname'";
  diag "Gtk2::Entry $pname pspec ",ref $pspec,
    ", value_type=",$pspec->get_value_type;

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

  {
    my $border = $entry->get ($pname); # undef by default
    ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $border,$border));
  }
  {
    $entry->set ($pname, {left=>1,right=>2,top=>3,bottom=>4});
    my $border = $entry->get ($pname); # undef by default
    ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $border,$border));
  }
}

#-----------------------------------------------------------------------------
# boxed -- Gtk2::Border

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
