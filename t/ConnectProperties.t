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
use Test::More tests => 64;

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

package main;
use Glib::Ex::ConnectProperties;


#-----------------------------------------------------------------------------
ok ($Glib::Ex::ConnectProperties::VERSION >= 1);
ok (Glib::Ex::ConnectProperties->VERSION >= 1);


#-----------------------------------------------------------------------------

{ my $pspec = Glib::ParamSpec->boolean ('foo','foo','blurb',0,['readable']);
  my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
  is (ref($subr), 'CODE');
  ok ($subr->(1,1));
  ok (! $subr->(1,0));
  ok (! $subr->(0,1));
  ok ($subr->(0,0));

  ok ($subr->(1,1));
  ok (! $subr->(1,undef));
  ok (! $subr->(undef,1));
  ok ($subr->(undef,undef));

  ok ($subr->(0,undef));
  ok ($subr->(undef,0));
  ok ($subr->('x',2));
  ok ($subr->('',0));
  ok ($subr->('',''));
  ok ($subr->(0,0));
  ok ($subr->(1,2));
}

{ my $pspec = Glib::ParamSpec->char ('foo','foo','blurb',
                                     32,127,32,['readable']);
  my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
  is (ref($subr), 'CODE');
  ok ($subr->(1,1));
  ok (! $subr->(1,2));

}

{ my $pspec = Glib::ParamSpec->string ('foo','foo','blurb',
                                       'default',['readable']);
  my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
  is (ref($subr), 'CODE');
  ok ($subr->('x','x'));
  ok (! $subr->('x',''));
  ok (! $subr->('x','X'));
  ok (! $subr->('x',undef));
  ok (! $subr->(undef,'x'));
  ok ($subr->(undef,undef));
}

{ my $pspec = Glib::ParamSpec->int ('foo','foo','blurb',
                                    0,100,0,['readable']);
  my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
  is (ref($subr), 'CODE');
  ok ($subr->(123,123));
  ok (! $subr->(123,0));
  ok (! $subr->(0,123));
  ok ($subr->(0,0));
}

{ my $pspec = Glib::ParamSpec->object ('foo','foo','blurb',
                                       'Glib::Object',['readable']);
  my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
  is (ref($subr), 'CODE');
  my $f1 = Foo->new;
  my $f2 = Foo->new;
  ok ($subr->($f1,$f1));
  ok (! $subr->($f1,$f2));
  ok (! $subr->($f1,undef));
  ok (! $subr->(undef,$f1));
  ok ($subr->(undef,undef));
}

{ my $pspec = Glib::ParamSpec->float ('foo','foo','blurb',
                                      0,100,0,['readable']);
  my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
  is (ref($subr), 'CODE');
  ok ($subr->(123,123));
  ok (! $subr->(123,0));
  ok (! $subr->(0,123));
  ok ($subr->(0,0));
}

{ my $pspec = Glib::ParamSpec->scalar ('foo','foo','blurb',['readable']);
  my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
  is (ref($subr), 'CODE');
  ok ($subr->(123,123));
  ok ($subr->('xyz','xyz'));
  ok (! $subr->('xyz',123));
}


#-----------------------------------------------------------------------------
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
  $obj1->set (myprop_one=>1);
  is ($obj1->get ('myprop-one'), 1);
  is ($obj1->get ('myprop-two'), 1);
  is ($obj2->get ('myprop-one'), 0);
  is ($obj2->get ('myprop-two'), 0);
}

{
  my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
  my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                               [$obj2,'myprop-two']);
  require Scalar::Util;
  Scalar::Util::weaken ($conn);

  my $weak_obj1 = $obj1;
  Scalar::Util::weaken ($weak_obj1);
  $obj1 = undef;
  is ('not defined',
      defined $weak_obj1 ? 'defined' : 'not defined',
      'obj1 not kept alive');

  my $weak_obj2 = $obj2;
  Scalar::Util::weaken ($weak_obj2);
  $obj2 = undef;
  is ('not defined',
      defined $weak_obj2 ? 'defined' : 'not defined',
      'obj2 not kept alive');

  is ('not defined',
      defined $conn ? 'defined' : 'not defined',
      'conn garbage collected when none left');
}

{
  my $obj1 = Foo->new (myprop_one => 1, myprop_two => 0);
  my $obj2 = Foo->new (myprop_one => 0, myprop_two => 1);
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                               [$obj2,'myprop-two']);
  Scalar::Util::weaken ($conn);

  $obj1 = undef;
  $obj2->set (myprop_two=>0);
  is (scalar @{$conn->{'array'}}, 1,
      'notice linked object gone');
}

exit 0;
