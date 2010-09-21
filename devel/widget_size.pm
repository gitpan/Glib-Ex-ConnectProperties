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



# widget:size:width
# widget:size:height

# widget-size:width
# widget-size:height

# widget:size-width
# widget:size-height

# wsize:width
# wsize:height

# widgetalloc:width
# widgetalloc:height

# widget-alloc:width
# widget-alloc:height

# widget:mapped
# widget:flag:mapped
# widget:flags:mapped
# wflags:mapped
# widget-flags:mapped
# widget-direction
# widget:direction


# container:empty
# container:non-empty
# container:count-children
#   emission hook of parent-set probably, as nothing on container itself



package Glib::Ex::ConnectProperties::Element::widget_size;
use 5.008;
use strict;
use warnings;
use Glib;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 10;

# uncomment this to run the ### lines
use Smart::Comments;


# my $conn = Glib::Ex::ConnectProperties->new
#   ([$widget, 'widget-size:width' ],
#    [$padding_spin, 'value']);

# my $conn = Glib::Ex::ConnectProperties->new
#   ([$widget, 'widget-allocation:x' ],
#    [$padding_spin, 'value']);


my %pspecs = do {
  # dummy name as paramspec name cannot be empty
  my $pspec = Glib::ParamSpec->int ('w',    # name
                                    'w',    # name
                                    '',     # blurb
                                    0,      # min
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

use constant read_signal => 'size-allocate';

sub get_value {
  my ($self) = @_;
  ### widget_size get_value(): $self->{'object'}->allocation->values
  my $method = $self->{'pname'};
  return $self->{'object'}->allocation->$method;
}
sub set_value {
  die "oops, model-rows is meant to be read-only";
}

1;
__END__
