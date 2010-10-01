# setting 'none' turns into 'ltr' or 'rtl' on read back


# widget#mapped
# widget-flags#mapped
#
# widget-direction
# widget-direction#dir
# widget#direction


# container#empty
# container#non-empty
# container#count-children
#   emission hook of parent-set probably, as nothing on container itself





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

our $VERSION = 11;

# uncomment this to run the ### lines
#use Smart::Comments;


# my $conn = Glib::Ex::ConnectProperties->new
#   ([$widget, 'widget-direction#dir' ],
#    [$combobox, 'active-nick' ]);

# widget-direction#default for fallback for all widgets?
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

use constant read_signals => 'direction-changed';

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


# =head2 Widget Text Direction
# 
# The C<Gtk2::Widget> text direction C<ltr> or C<rtl> can be accessed from
# ConnectProperties with
# 
#     widget-direction#dir     enum Gtk2::TextDirection
# 
# This is the widget C<get_direction> and C<set_direction> methods and might
# for instance be used to keep the direction the same in a set of widgets.
# 
#     Glib::Ex::ConnectProperties->new
#       ([$label1, 'widget-direction#dir'],
#        [$label2, 'widget-direction#dir']);
#
# Setting C<none> probably doesn't work.  It can be set into a direction,
# but on reading it back C<get_direction> turns C<none> into the global
# default C<ltr> or C<rtl>.
# 
