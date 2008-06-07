#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

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
use Test::More tests => 35;

use Glib::Ex::ConnectProperties;

SKIP: {
  if (! eval { require Gtk2 } || ! Gtk2->init_check) {
    skip 'due to no DISPLAY available', 35;
  }

  { my $about = Gtk2::AboutDialog->new;
    my $pspec = $about->find_property ('artists') or die;
    my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
    is (ref($subr), 'CODE');
    ok ($subr->([],[]));
    ok ($subr->([],undef));
    ok ($subr->(undef,[]));
    ok ($subr->(undef,undef));

    ok ($subr->(['x'],['x']));
    ok (! $subr->(['x'],[]));
    ok (! $subr->(['x'],undef));
    ok (! $subr->([],['x']));
    ok (! $subr->(undef,['x']));

    ok ($subr->(['a','b'],['a','b']));
    ok (! $subr->(['a','b'],['a','x']));
  }

  { my $entry = Gtk2::Entry->new;
    my $pspec = $entry->find_property ('inner-border') or die;
    my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
    is (ref($subr), 'CODE');

    ok ($subr->({left=>1,right=>2,top=>3,bottom=>4},
                {left=>1,right=>2,top=>3,bottom=>4}));
    ok (! $subr->({left=>1,right=>2,top=>3,bottom=>4},
                  {left=>0,right=>2,top=>3,bottom=>4}));
    ok (! $subr->({left=>1,right=>2,top=>3,bottom=>4},
                  {left=>1,right=>0,top=>3,bottom=>4}));
    ok (! $subr->({left=>1,right=>2,top=>3,bottom=>4},
                  {left=>1,right=>2,top=>0,bottom=>4}));
    ok (! $subr->({left=>1,right=>2,top=>3,bottom=>4},
                  {left=>1,right=>2,top=>3,bottom=>0}));

    my $b1 = $entry->get ('inner-border'); # undef by default
    ok ($subr->($b1,$b1));
  }

  { my $label = Gtk2::Label->new;
    my $pspec = $label->find_property ('justify') or die;
    my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
    is (ref($subr), 'CODE');
    ok ($subr->('right','right'));
    ok ($subr->('left','left'));
    ok (! $subr->('right','left'));
  }

  { my $pspec = Glib::ParamSpec->boxed ('foo','foo','blurb',
                                        'Gtk2::Gdk::Color',['readable']);
    my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
    is (ref($subr), 'CODE');

    my $c1 = Gtk2::Gdk::Color->new (1,2,3);
    my $c1b = Gtk2::Gdk::Color->new (1,2,3);
    my $c2 = Gtk2::Gdk::Color->new (0,2,3);
    my $c3 = Gtk2::Gdk::Color->new (1,0,3);
    my $c4 = Gtk2::Gdk::Color->new (1,2,0);
    ok ($subr->($c1,$c1));
    ok ($subr->($c1,$c1b));
    ok (! $subr->($c1,$c2));
    ok (! $subr->($c1,$c3));
    ok (! $subr->($c1,$c4));
  }

  { my $pspec = Glib::ParamSpec->boxed ('foo','foo','blurb',
                                        'Gtk2::Gdk::Cursor',['readable']);
    my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
    is (ref($subr), 'CODE');

    my $c1 = Gtk2::Gdk::Cursor->new ('watch');
    my $c1b = Gtk2::Gdk::Cursor->new ('watch');
    my $c2 = Gtk2::Gdk::Cursor->new ('hand1');
    ok ($subr->($c1,$c1));
    ok ($subr->($c1,$c1b));
    ok (! $subr->($c1,$c2));

    my $display = Gtk2::Gdk::Display->get_default
      or die "oops, no default display";
    my $window = $display->get_default_screen->get_root_window;
    my $m = Gtk2::Gdk::Bitmap->create_from_data ($window, "\0", 1, 1);
    my $color = Gtk2::Gdk::Color->new (0,0,0);
    my $cp1 = Gtk2::Gdk::Cursor->new_from_pixmap ($m,$m, $color,$color, 0,0);
    my $cp2 = Gtk2::Gdk::Cursor->new_from_pixmap ($m,$m, $color,$color, 0,0);
    ok ($subr->($cp1,$cp1));
    ok (! $subr->($cp1,$cp2));
  }
}

