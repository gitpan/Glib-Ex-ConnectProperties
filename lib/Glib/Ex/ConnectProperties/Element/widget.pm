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

our $VERSION = 14;

# uncomment this to run the ### lines
#use Smart::Comments;

# For reference, among the various "-set" and "-changed" signals,
#
#    parent-set   - already a "parent" property
#
# Other possibilities:
#     widget#screen-nodefault      only when has-screen
#     
#     widget#mapped
#     widget-flags#mapped
#         change on map-event, unmap-event, or unmap action?
#
#     widget-style#pname         style-set prop readable
#     widget-style#fg.normal     writable modify-fg
#     widget-style#property.foo
#     widget-style-property#pname     style-set prop readable
#

my %pspecs = (direction => Glib::ParamSpec->enum ('direction',
                                                  'direction',
                                                  '', # blurb
                                                  'Gtk2::TextDirection',
                                                  'none', # default, unused
                                                  Glib::G_PARAM_READWRITE),
              state => Glib::ParamSpec->enum ('state',
                                              'state',
                                              '', # blurb
                                              'Gtk2::StateType',
                                              'normal', # default, unused
                                              Glib::G_PARAM_READWRITE),
              toplevel => Glib::ParamSpec->object ('toplevel',
                                                   'toplevel',
                                                   '', # blurb
                                                   'Gtk2::Widget',
                                                   'readable'),
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
  $pspecs{'has-screen'} = Glib::ParamSpec->boolean ('has-screen',
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
  return ($read_signal{$pname} || "$pname-changed");
}

my %get_method = ('has-screen' => 'has_screen',
                  toplevel     => \&_widget_get_toplevel,
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
  my $set_method = "set_$self->{'pname'}";
  return $self->{'object'}->$set_method ($newval);
}

sub _widget_get_toplevel {
  my ($widget) = @_;
  my $toplevel;
  return (($toplevel = $widget->get_toplevel) && $toplevel->flags & 'toplevel'
          ? $toplevel
          : undef);
}

1;
__END__
