#!/usr/bin/perl

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

BEGIN {
  my $have_test_weaken = eval "use Test::Weaken 2.000; 1";
  if (! $have_test_weaken) {
    plan skip_all => "due to Test::Weaken 2.000 not available -- $@";
  }
  diag ("Test::Weaken version ", Test::Weaken->VERSION);

  plan tests => 3;

 SKIP: { eval 'use Test::NoWarnings; 1'
           or skip 'Test::NoWarnings not available', 1; }
}

require Glib::Ex::ConnectProperties;
require Glib;

#-----------------------------------------------------------------------------
package Foo;
use strict;
use warnings;
use Glib;
use Glib::Object::Subclass
  Glib::Object::,
  properties => [Glib::ParamSpec->boolean
                 ('myprop-one',
                  'myprop-one',
                  'Blurb.',
                  0,
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->boolean
                 ('myprop-two',
                  'myprop-two',
                  'Blurb.',
                  0,
                  Glib::G_PARAM_READWRITE)
                ];

#-----------------------------------------------------------------------------
package main;
use strict;
use warnings;

{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
       my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
       my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                                    [$obj2,'myprop-two']);
       return [ $obj1, $obj2, $conn ];
     });
  is ($leaks, undef, 'deep garbage collection');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
       my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
       my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                                    [$obj2,'myprop-two']);
       undef $obj1;
       undef $obj2;
       return $conn;
     });
  is ($leaks, undef, 'deep garbage collection -- with objects already gone');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

exit 0;
