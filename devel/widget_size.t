#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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
use Glib::Ex::ConnectProperties;
use Test::More;

use lib 't';
use MyTestHelpers;
# BEGIN { MyTestHelpers::nowarnings() }

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY";
MyTestHelpers::glib_gtk_versions();

plan tests => 2;


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

{
  my $toplevel = Gtk2::Window->new('popup');

  my $fixed = Gtk2::Fixed->new;
  $toplevel->add ($fixed);

  my $draw = Gtk2::DrawingArea->new;
  $draw->set_size_request (2000, 1000);
  $fixed->put ($draw, 10,10);

  $toplevel->show_all;
  # might need to loop to get size-request applied by $fixed
  MyTestHelpers::main_iterations();

  my $foo = Foo->new;
  my $bar = Foo->new;
  Glib::Ex::ConnectProperties->new ([$draw,'widget-size:width'],
                                    [$foo,'mystring']);
  Glib::Ex::ConnectProperties->new ([$draw,'widget-size:height'],
                                    [$bar,'mystring']);
  is ($foo->get('mystring'), 2000);
  is ($bar->get('mystring'), 1000);

  #   $draw->signal_connect (size_allocate => sub {
  #                            diag "draw size-allocate";
  #                          });
  #   diag $draw->size_request->width;

  $draw->set_size_request (500, 300);
  # must loop for $fixed to act on queued resize
  MyTestHelpers::main_iterations();

  is ($foo->get('mystring'), 500);
  is ($bar->get('mystring'), 300);

  $toplevel->destroy;
}

# {
#   my $foo = Foo->new;
#   my $fixed = Gtk2::Layout->new;
#   my $drawing = Gtk2::DrawingArea->new;
#   $fixed->put ($drawing, 0, 0);
# 
#   my $conn = Glib::Ex::ConnectProperties->new
#     ([$toplevel, 'widget-size:width'],
#      [$foo, 'mystring']);
# 
#   like ($foo->get('mystring'), '/^[0-9]+$/');
# }

