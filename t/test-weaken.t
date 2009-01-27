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

my $have_test_weaken = eval { require Test::Weaken };
if (! $have_test_weaken) {
  plan skip_all => "Test::Weaken not available -- $@";
}

plan tests => 2;

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
  my @weaken = Test::Weaken::poof
    (sub {
       my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
       my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
       my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                                    [$obj2,'myprop-two']);
       return [ $obj1, $obj2, $conn ];
     });
  diag "Test-Weaken ", explain \@weaken;
  my $unfreed = @{$weaken[2]} + @{$weaken[3]};
  is ($unfreed, 0, 'Test::Weaken deep garbage collection');
}

{
  my @weaken = Test::Weaken::poof
    (sub {
       my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
       my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
       my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                                    [$obj2,'myprop-two']);
       undef $obj1;
       undef $obj2;
       return $conn;
     });
  diag "Test-Weaken ", explain \@weaken;
  my $unfreed = @{$weaken[2]} + @{$weaken[3]};
  is ($unfreed, 0, 'Test::Weaken with objects already gone');
}

exit 0;
