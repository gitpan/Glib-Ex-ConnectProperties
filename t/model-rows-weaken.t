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

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# 2.002 for "ignore"
eval "use Test::Weaken 2.002; 1"
  or plan skip_all => "due to Test::Weaken 2.002 not available -- $@";
diag ("Test::Weaken version ", Test::Weaken->VERSION);

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";
MyTestHelpers::glib_gtk_versions();

plan tests => 4;

require Glib::Ex::ConnectProperties;
require Glib;

#-----------------------------------------------------------------------------
{
  package MyClass;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [ Glib::ParamSpec->boolean
                      ('mybool',
                       'mybool',
                       'Blurb.',
                       0, # default
                       Glib::G_PARAM_READWRITE),
                    ];
}

#------------------------------------------------------------------------------

# "permanent" new() connp object is gc'ed when all its objects go
{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $foo = MyClass->new;
       my $model = Gtk2::TreeStore->new ('Glib::String');
       my $conn = Glib::Ex::ConnectProperties->new
         ([$model, 'model-rows#empty'],
          [$foo,   'mybool']);
       return [ $foo, $model, $conn ];
     });
  is ($leaks, undef, 'new() deep gc');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

# "permanent" new() connp object with objects already gone
{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $foo = MyClass->new;
       my $model = Gtk2::TreeStore->new ('Glib::String');
       my $conn = Glib::Ex::ConnectProperties->new
         ([$model, 'model-rows#empty'],
          [$foo,   'mybool']);
       undef $foo;
       undef $model;
       return $conn;
     });
  is ($leaks, undef, 'new() deep gc -- with objects already gone');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

# "dynamic" connp object
{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $foo = MyClass->new;
       my $model = Gtk2::TreeStore->new ('Glib::String');
       my $conn = Glib::Ex::ConnectProperties->dynamic
         ([$model, 'model-rows#empty'],
          [$foo,   'mybool']);
       return [ $foo, $model, $conn ];
     });
  is ($leaks, undef, 'dynamic() deep gc');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

# "dynamic" connp object with targets persisting
{
  my $foo = MyClass->new;
  my $model = Gtk2::TreeStore->new ('Glib::String');
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return Glib::Ex::ConnectProperties->dynamic
           ([$model, 'model-rows#empty'],
            [$foo,   'mybool']);
       },
       ignore => sub {
         my ($ref) = @_;
         return ($ref == $foo || $ref == $model);
       },
     });
  is ($leaks, undef, 'dynamic() deep gc -- with objects persisting');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
    my $unfreed = $leaks->unfreed_proberefs;
    foreach my $proberef (@$unfreed) {
      diag "  search $proberef";
      MyTestHelpers::findrefs($proberef);
    }
  }
}

exit 0;
