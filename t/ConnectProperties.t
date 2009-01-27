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
use Test::More tests => 86;


my $want_version = 4;
ok ($Glib::Ex::ConnectProperties::VERSION >= $want_version,
    'VERSION variable');
ok (Glib::Ex::ConnectProperties->VERSION  >= $want_version,
    'VERSION class method');
Glib::Ex::ConnectProperties->VERSION ($want_version);


diag ("Perl-Glib version ",Glib->VERSION);
diag ("Compiled against Glib version ",
      Glib::MAJOR_VERSION(), ".",
      Glib::MINOR_VERSION(), ".",
      Glib::MICRO_VERSION(), ".");
diag ("Running on       Glib version ",
      Glib::major_version(), ".",
      Glib::minor_version(), ".",
      Glib::micro_version(), ".");

## no critic (ProtectPrivateSubs)


#-----------------------------------------------------------------------------
package Foo;
use strict;
use warnings;
use Glib;
use Glib::Object::Subclass
  'Glib::Object',
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
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->double
                 ('writeonly-double',
                  'writeonly-double',
                  'Blurb.',
                  -1000, 1000, 111,
                  ['writable']),

                 Glib::ParamSpec->float
                 ('readonly-float',
                  'readonly-float',
                  'Blurb.',
                  -2000, 2000, 222,
                  ['readable']),
                ];

#-----------------------------------------------------------------------------
package main;
use strict;
use warnings;

# return true if there's any signal handlers connected to $obj
sub any_signal_connections {
  my ($obj) = @_;
  my @connected = grep {$obj->signal_handler_is_connected ($_)} (0 .. 500);
  if (@connected) {
    diag "$obj signal handlers connected: ",join(' ',@connected),"\n";
    return 1;
  }
  return 0;
}


#-----------------------------------------------------------------------------
# values_cmp

my $have_values_cmp = Glib::ParamSpec->can('values_cmp');
diag "have values_cmp(): ", ($have_values_cmp ? 'yes' : 'no');

# SKIP: {
#   $have_values_cmp or skip 'due to no values_cmp()', 1;
# }


#-----------------------------------------------------------------------------
# boolean

{ my $pspec = Glib::ParamSpec->boolean ('foo','foo','blurb',0,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,1));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,0));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,1));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,0));

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,1));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,1));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,undef));

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,undef));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,0));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'x',2));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, '',0));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, '',''));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,0));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,2));
}

#-----------------------------------------------------------------------------
# string

{ my $pspec = Glib::ParamSpec->string ('foo','foo','blurb',
                                       'default',['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'x','x'));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'x',''));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'x','X'));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'x',undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,'x'));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,undef));
}

#-----------------------------------------------------------------------------
# char

{ my $pspec = Glib::ParamSpec->char ('foo','foo','blurb',
                                     32,127,32,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,1));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,2));

}

#-----------------------------------------------------------------------------
# int

{ my $pspec = Glib::ParamSpec->int ('foo','foo','blurb',
                                    0,100,0,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,123));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,0));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,123));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,0));
}

#-----------------------------------------------------------------------------
# float

{ my $pspec = Glib::ParamSpec->float ('foo','foo','blurb',
                                      0,100,0,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,123));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,0));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,123));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,0));

  my $epsilon = $pspec->get_epsilon;
  diag "  epsilon is $epsilon";
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0, $epsilon / 2));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0, - $epsilon / 2));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $epsilon / 2, 0));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, - $epsilon / 2, 0));
}

#-----------------------------------------------------------------------------
# double

{ my $pspec = Glib::ParamSpec->double ('foo','foo','blurb',
                                       0,100,0,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,123));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,0));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,123));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,0));

  my $epsilon = $pspec->get_epsilon;
  diag "  epsilon is $epsilon";
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0, $epsilon / 2));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0, - $epsilon / 2));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $epsilon / 2, 0));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, - $epsilon / 2, 0));
}

#-----------------------------------------------------------------------------
# object

{ my $pspec = Glib::ParamSpec->object ('foo','foo','blurb',
                                       'Glib::Object',['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  my $f1 = Foo->new;
  my $f2 = Foo->new;
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $f1,$f1));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $f1,$f2));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $f1,undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,$f1));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,undef));
}

#-----------------------------------------------------------------------------
# scalar

{ my $pspec = Glib::ParamSpec->scalar ('foo','foo','blurb',['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,123));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'xyz','xyz'));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'xyz',123));
}


#-----------------------------------------------------------------------------
# boxed -- strv

{ my $pspec = Glib::ParamSpec->boxed ('foo','foo','blurb',
                                      'Glib::Strv',['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

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
# disconnect ()

{
  my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
  my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                               [$obj2,'myprop-two']);

  is ($obj1->get ('myprop-one'), 1);
  is ($obj1->get ('myprop-two'), 1);
  is ($obj2->get ('myprop-one'), 0);
  is ($obj2->get ('myprop-two'), 1);

  $obj2->set (myprop_two=>0);
  is ($obj1->get ('myprop-one'), 0);
  is ($obj1->get ('myprop-two'), 1);
  is ($obj2->get ('myprop-one'), 0);
  is ($obj2->get ('myprop-two'), 0);

  $conn->disconnect;
  ok (! any_signal_connections($obj1));
  ok (! any_signal_connections($obj2));

  $obj1->set (myprop_one=>1);
  is ($obj1->get ('myprop-one'), 1);
  is ($obj1->get ('myprop-two'), 1);
  is ($obj2->get ('myprop-one'), 0);
  is ($obj2->get ('myprop-two'), 0);
}

#-----------------------------------------------------------------------------
# weaken

{
  my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
  my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                               [$obj2,'myprop-two']);
  require Scalar::Util;

  my $weak_obj1 = $obj1;
  Scalar::Util::weaken ($weak_obj1);
  $obj1 = undef;
  is ($weak_obj1, undef, 'obj1 not kept alive');

  my $weak_obj2 = $obj2;
  Scalar::Util::weaken ($weak_obj2);
  $obj2 = undef;
  is ($weak_obj2, undef, 'obj2 not kept alive');

  Scalar::Util::weaken ($conn);
  is ($conn, undef, 'conn garbage collected when none left');
}

{
  my $obj1 = Foo->new (myprop_one => 1, myprop_two => 0);
  my $obj2 = Foo->new (myprop_one => 0, myprop_two => 1);
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                               [$obj2,'myprop-two']);

  $obj1 = undef;
  $obj2->set (myprop_two=>0);
  is (scalar @{$conn->{'array'}}, 1,
      'notice linked object gone');
}

#-----------------------------------------------------------------------------
# write-only

{
  my $obj1 = Foo->new;
  my $obj2 = Foo->new;
  my $obj3 = Foo->new; $obj3->{'readonly-float'} = 999;
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'writeonly-double'],
                                               [$obj2,'writeonly-double'],
                                               [$obj3,'readonly-float']);
  is ($obj1->{'writeonly_double'}, 999,
      'obj1 writeonly-double set initially');
  is ($obj2->{'writeonly_double'}, 999,
      'obj2 writeonly-double set initially');
}

{
  my $obj1 = Foo->new;
  my $obj2 = Foo->new;
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'writeonly-double'],
                                               [$obj2,'readonly-float']);
  $obj2->{'readonly-float'} = 999;
  $obj2->notify ('readonly-float');
  is ($obj1->{'writeonly_double'}, 999,
      'writeonly-double set by notify');
}

SKIP: {
  Glib::ParamSpec->can('value_validate')
      or skip 'due to value_validate() not available', 1;
  my $obj1 = Foo->new; $obj1->{'readonly-float'} = 1500;
  my $obj2 = Foo->new;
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'readonly-float'],
                                               [$obj2,'writeonly-double']);
  is ($obj2->{'writeonly_double'}, 1000,
      'obj1 writeonly-double set initially with value_validate clamp');
}

exit 0;
