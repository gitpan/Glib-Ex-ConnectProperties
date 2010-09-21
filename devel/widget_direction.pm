# setting 'none' turns into 'ltr' or 'rtl' on read back







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


package Glib::Ex::ConnectProperties::Element::widget_direction;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Gtk2;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 10;

# uncomment this to run the ### lines
#use Smart::Comments;


# my $conn = Glib::Ex::ConnectProperties->new
#   ([$widget, 'widget-direction:dir' ],
#    [$combobox, 'active-nick' ]);

# widget-direction:default for fallback for all widgets?
# not actually associated with a particular widget

my %pspecs = (dir => Glib::ParamSpec->enum ('direction',
                                            'direction',
                                            '',          # blurb
                                            'Gtk2::TextDirection',
                                            'none',      # default
                                            Glib::G_PARAM_READWRITE));
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

use constant read_signal => 'direction-changed';

sub get_value {
  my ($self) = @_;
  return $self->{'object'}->get_direction;
}
sub set_value {
  my ($self, $value) = @_;
  return $self->{'object'}->set_direction ($value);
}

1;
__END__
