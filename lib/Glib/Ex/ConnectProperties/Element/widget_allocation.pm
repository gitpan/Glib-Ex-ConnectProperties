# Copyright 2010 Kevin Ryde

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


package Glib::Ex::ConnectProperties::Element::widget_allocation;
use 5.008;
use strict;
use warnings;
use Glib;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 11;

# uncomment this to run the ### lines
#use Smart::Comments;


my %pspecs = do {
  # dummy names and dummy range, just want an "int" type
  # note paramspec names cannot be empty strings
  my $pspec = Glib::ParamSpec->int ('w-a',  # name
                                    'w-a',  # name
                                    '',     # blurb
                                    -32768, # min
                                    32767,  # max
                                    0,      # default
                                    ['readable']);
  (x      => $pspec,
   y      => $pspec,
   width  => $pspec,
   height => $pspec)
};
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

use constant read_signals => 'size-allocate';

sub get_value {
  my ($self) = @_;
  ### widget_allocation get_value(): $self->{'object'}->allocation->values
  my $method = $self->{'pname'};
  return $self->{'object'}->allocation->$method;
}

sub set_value {
  die "ConnectProperties: oops, widget-allocation is meant to be read-only";
}

1;
__END__
