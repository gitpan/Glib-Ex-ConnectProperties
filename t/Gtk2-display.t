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
my $have_display = Gtk2->init_check;
if (! $have_display) {
  plan skip_all => "due to no DISPLAY";
}
plan tests => 16;

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
# strv from AboutDialog

{ my $about = Gtk2::AboutDialog->new;
  my $pname = 'artists';
  my $pspec = $about->find_property ($pname)
    or die "Oops, Gtk2::AboutDialog doesn't have property '$pname'";
  diag "Gtk2::AboutDialog pspec ",ref $pspec,
    ", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, [],undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,[]));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, [],[]));

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['x'],['x']));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['x'],[]));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['x'],undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, [],['x']));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,['x']));

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['a','b'],['a','b']));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['a','b'],['a','x']));
}

#-----------------------------------------------------------------------------
# GdkCursor boxed

{ my $pspec = Glib::ParamSpec->boxed ('foo','foo','blurb',
                                      'Gtk2::Gdk::Cursor',['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  my $c1 = Gtk2::Gdk::Cursor->new ('watch');
  my $c1b = Gtk2::Gdk::Cursor->new ('watch');
  my $c2 = Gtk2::Gdk::Cursor->new ('hand1');
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c1));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c1b));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c2));

 SKIP: {
    my $default_display = Gtk2::Gdk::Display->get_default;
    if (! $default_display) {
      skip "due to no default display", 2;
    }
    my $window = $default_display->get_default_screen->get_root_window;
    my $m = Gtk2::Gdk::Bitmap->create_from_data ($window, "\0", 1, 1);
    my $color = Gtk2::Gdk::Color->new (0,0,0);
    my $cp1 = Gtk2::Gdk::Cursor->new_from_pixmap ($m,$m, $color,$color, 0,0);
    my $cp2 = Gtk2::Gdk::Cursor->new_from_pixmap ($m,$m, $color,$color, 0,0);
    ok (Glib::Ex::ConnectProperties::_pspec_equal
        ($pspec, $cp1,$cp1,
         'same cursor from bitmap'));
    ok (! Glib::Ex::ConnectProperties::_pspec_equal
        ($pspec, $cp1,$cp2,
         'different cursors from bitmap'));
  }
}

exit 0;
