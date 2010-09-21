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
# BEGIN { MyTestHelpers::nowarnings() }

require Glib::Ex::ConnectProperties;

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";
MyTestHelpers::glib_gtk_versions();

plan tests => 6;


{
  package Foo;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->string
                     ('mystring',
                      'mystring',
                      'Blurb.',
                      '', # default
                      Glib::G_PARAM_READWRITE),
                    ];
}

#------------------------------------------------------------------------------
# direction

{
  my $foo = Foo->new (mystring => 'initial mystring');

  my $label = Gtk2::Label->new;
  Glib::Ex::ConnectProperties->new
      ([$label, 'widget:direction'],
       [$foo,   'mystring']);
  is ($label->get_direction, $foo->get('mystring'));

  $label->set_direction ('none');
  is ($label->get_direction, $foo->get('mystring'));

  $label->set_direction ('ltr');
  is ($label->get_direction, $foo->get('mystring'));

  $label->set_direction ('rtl');
  is ($label->get_direction, $foo->get('mystring'));

  $foo->set (mystring => 'ltr');
  is ($label->get_direction, $foo->get('mystring'));

  $foo->set (mystring => 'rtl');
  is ($label->get_direction, $foo->get('mystring'));
}

exit 0;
