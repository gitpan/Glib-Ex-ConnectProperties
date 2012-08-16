# Copyright 2010, 2011 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.

package Glib::Ex::ConnectProperties::Element::screen_size;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Scalar::Util;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 18;

# uncomment this to run the ### lines
#use Smart::Comments;


# _gdk_x11_screen_size_changed() emits size-changed if pixels changed, but
# not if pixels same but millimetres changed.
#
# _gdk_x11_screen_process_monitors_change() emits monitors-changed for any
# RandrNotify.
#

my %pspecs = do {
  # dummy name as paramspec name cannot be empty string
  my $pspec = Glib::ParamSpec->int ('wh',      # name, unused
                                    'wh',      # nick, unused
                                    '',        # blurb, unused
                                    0, 32767,  # min,max, unused
                                    0,         # default, unused
                                    'readable');
  ('width'     => $pspec,
   'height'    => $pspec,
   'width-mm'  => $pspec,
   'height-mm' => $pspec,
  )
};
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

sub read_signals {
  my ($self) = @_;
  if ($self->{'pname'} =~ /mm/) {
    my $screen = $self->{'object'};
    if ($screen->signal_query('monitors-changed')) {
      # new in gtk 2.14
      return 'monitors-changed';
    } else {
      # before gtk 2.14 there was no randr listening and width_mm/height_mm
      # were unchanging
      return;
    }
  } else {
    return 'size-changed';
  }
}

my %method = ('width'     => 'get_width',
              'height'    => 'get_height',
              'width-mm'  => 'get_width_mm',
              'height-mm' => 'get_height_mm',
             );
sub get_value {
  my ($self) = @_;
  my $method = $method{$self->{'pname'}};
  return $self->{'object'}->$method;
}

sub set_value {
  die "oops, screen-size is meant to be read-only";
}

1;
