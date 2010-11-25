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


# widget-toplevel#gdkwindow
#    would track realize on toplevel ...
#
# widget-toplevel#window
# widget-toplevel#win
# widget-get-toplevel#window
# widget-get-toplevel#widget

package Glib::Ex::ConnectProperties::Element::widget_toplevel;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Gtk2;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 12;

# uncomment this to run the ### lines
#use Smart::Comments;


# my $conn = Glib::Ex::ConnectProperties->new
#   ([$widget, 'widget-toplevel#dir' ],
#    [$combobox, 'active-nick' ]);

# widget-toplevel#default for fallback for all widgets?
# not actually associated with a particular widget

my %pspecs = (widget => Glib::ParamSpec->object ('widget',
                                                 'widget',
                                                 '',          # blurb
                                                 'Gtk2::Widget',
                                                 'readable'));
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

use constant read_signals => 'hierarchy-changed';

sub get_value {
  my ($self) = @_;
  my $toplevel = $self->{'object'}->get_toplevel;
  return ($toplevel->flags & 'toplevel' ? $toplevel : undef);
}
sub set_value {
  die "oops, widget-toplevel is meant to be read-only";
}

1;
__END__


# =head2 Widget Toplevel
# 
# The toplevel window parent of a C<Gtk2::Widget> can be accessed from
# ConnectProperties with
# 
#     widget-toplevel#widget     Gtk2::Window or undef, read-only
# 
# This is C<< $widget->get_toplevel >> with its recommended
# C<< $widget->toplevel >> flag check, so it's a top level <Gtk2::Window> or
# C<undef> if the given widget isn't under a toplevel.
# 
#     Glib::Ex::ConnectProperties->new
#       ([$label1, 'widget-toplevel#widget'],
#        [$label2, 'transient-for']);
#
# C<widget-toplevel#widget> can be used on toplevel C<Gtk2::Window> itself,
# but the value is just that toplevel itself and never changes.  It can be
# used on a C<Gtk2::Plug> too, and in that case is like any other widget,
# giving the true toplevel of its parent C<Gtk2::Socket> when it's in a
# socket.
