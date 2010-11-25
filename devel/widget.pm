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


package Glib::Ex::ConnectProperties::Element::widget;
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

# For reference, among the various "-set" and "-changed" signals,
#
#    parent-set   - already a "parent" property
#

my %pspecs = (direction => Glib::ParamSpec->enum ('direction',
                                                  'direction',
                                                  '', # blurb
                                                  'Gtk2::TextDirection',
                                                  Glib::G_PARAM_READWRITE),
              state => Glib::ParamSpec->enum ('state',
                                              'state',
                                              '', # blurb
                                              'Gtk2::StateType',
                                              Glib::G_PARAM_READWRITE),
              toplevel => Glib::ParamSpec->object ('toplevel',
                                                   'toplevel',
                                                   '', # blurb
                                                   'Gtk2::Window',
                                                   'readable')
             );
my $pspec_screen_writable;
if (Gtk2::Widget->can('get_screen')) {
  # get_screen() new in Gtk 2.2
  $pspecs{'screen'} = Glib::ParamSpec->object ('screen',
                                               'screen',
                                               '', # blurb
                                               'Gtk2::Gdk::Screen',
                                               'readable');
  $pspec_screen_writable = Glib::ParamSpec->object ('screen',
                                                    'screen',
                                                    '', # blurb
                                                    'Gtk2::Gdk::Screen',
                                                    Glib::G_PARAM_READWRITE)
}
if (Gtk2::Widget->can('has_screen')) {
  # has_screen() new in Gtk 2.2
  $pspecs{'has-screen'} = Glib::ParamSpec->object ('has-screen',
                                                   'has-screen',
                                                   '', # blurb
                                                   0, # default
                                                   'readable');
}
sub find_property {
  my ($self) = @_;
  my $pname = $self->{'pname'};
  if ($pname eq 'screen' && $self->{'object'}->can('set_screen')) {
    return $pspec_screen_writable;
  }
  return $pspecs{$pname};
}

my %read_signal = ('has-screen' => 'screen-changed',
                   toplevel     => 'hierarchy-changed');
sub read_signals {
  my ($self) = @_;
  my $pname = $self->{'pname'};
  return ($read_signal{$pname} || "$pname-changed")
}

my %get_method = ('has-screen' => 'has_screen',
                  toplevel     => \&_get_toplevel,
                  (Gtk2::Widget->can('get_state') # new in Gtk 2.18
                   ? ()
                   : (state => 'state')),  # otherwise field directly
                 );

sub get_value {
  my ($self) = @_;
  my $pname = $self->{'pname'};
  my $get_method = $get_method{$pname} || "get_$pname";
  return $self->{'object'}->$get_method;
}
sub set_value {
  my ($self, $newval) = @_;
  my $pname = $self->{'pname'};
  my $get_method = $get_method{$pname} || "set_$pname";
  return $self->{'object'}->$set_method ($newval);
}

sub _get_toplevel {
  my ($widget) = @_;
  my $toplevel;
  return (($toplevel = $widget->get_toplevel) && $toplevel->flags & 'toplevel'
          ? $toplevel
          : undef);
}

1;
__END__


# =head2 Widget Extras
# 
# The following various widget attributes can be accessed from
# ConnectProperties.
# 
#     widget#direction      TextDirection enum
#     widget#screen         Gtk2::Gdk::Screen
#     widget#has-screen     boolean, read-only
#     widget#state          Gtk2::StateType enum
#     widget#toplevel       Gtk2::Window or undef, read-only
#
# These things aren't properties as such (though perhaps they could have
# been) but instead have get/set methods and then report changes with
# signals such as C<direction-changed> or C<state-changed>.
#
# =over
#
# =item *
#
# C<widget#direction> is the "ltr" or "rtl" text direction, per
# C<get_direction> and C<set_direction> methods.
#
# Currently if "none" is set then it reads back as "ltr" or "rtl" following
# the default.  This probably won't work very well with ConnectProperties,
# except to a forced C<write_only> target.
#
# =item *
#
# C<widget#screen> and C<widget#has-screen> are available in Gtk 2.2 up.
#
# C<widget#screen> uses the C<get_screen> method and so gives the default
# screen until the widget is added to a toplevel C<Gtk2::Window> or similar
# to determine the screen.
#
# C<widget#screen> is read-only for most widgets, but is writable for
# anything with a C<set_screen> method such as C<Gtk2::Menu>.
# C<Gtk2::Window> has a plain C<screen> property so there's no need for this
# special C<widget#screen> there.
#
# =item *
#
# C<widget#toplevel> is C<get_toplevel> plus its recommended
# C<< $topwidget->toplevel >> flag check so as to give only a
# C<Gtk2::Window> or similar, and is C<undef> until then.
# 
#     Glib::Ex::ConnectProperties->new
#       ([$toolitem, 'widget#toplevel'],
#        [$dialog,   'transient-for']);
#
# =back




