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


package Glib::Ex::ConnectProperties::Element::response_sensitive;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Gtk2;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 13;

# uncomment this to run the ### lines
#use Smart::Comments;

my $get_widget_for_response
  = (Gtk2::Dialog->can('get_widget_for_response') # new in Gtk 2.20
     ? 'get_widget_for_response'
     : do {
       require List::Util;
       sub {
         my ($dialog, $response) = @_;
         return List::Util::first {$_->get_response_for_widget eq $response}
           $object->get_action_area->get_children;
       }
     });

my $pspec = Glib::ParamSpec->boolean ('sensitive',
                                      'sensitive',
                                      '', # blurb
                                      1,  # default
                                      Glib::G_PARAM_READWRITE);
my $pspec_readonly = Glib::ParamSpec->boolean ('sensitive',
                                               'sensitive',
                                               '', # blurb
                                               1,  # default
                                               'readable');
my %response_types;
@response_types{map {$_->{'nick'}}
                  Glib::Type->list_values('Gtk2::ResponseType')} = ();

sub find_property {
  my ($self) = @_;
  my $pname = $self->{'pname'};
  my $object;
  return ((exists $response_types{$pname} || $pname =~ /^-?\d+$/)
          && ($self->{'object'}->can('get_response_for_widget')
              ? $pspec
              : $pspec_readonly));
}

sub connect_signals {
  my ($self) = @_;
  my $pname = $self->{'pname'};
  my $button = $self->{'object'}->$get_widget_for_response($pname)
    || croak "No widget for response $pname";

  $self->{'ids'} = Glib::Ex::SignalIds->new
    ($button,
     $model->signal_connect ('notify::sensitive',
                             \&Glib::Ex::ConnectProperties::_do_read_handler,
                             $self));
}

sub get_value {
  my ($self, $value) = @_;
  my $button;
  return (($button = $self->{'object'}->$get_widget_for_response($self->{'pname'}))
          ? $button->get_sensitive
          : 1);
}
sub set_value {
  my ($self, $value) = @_;
  $self->{'object'}->set_response_sensitive ($self->{'pname'}, $value);
}

1;
__END__


=head2 Response Sensitive

Response sensitivity on a C<Gtk2::Dialog>, C<Gtk2::InfoBar> or similar can
be accessed from ConnectProperties with

    response-sensitive#ok       boolean
    response-sensitive#123      boolean

The property name is either a C<Gtk2::ResponseType> nick or name, or an
integer for application defined responses (usually a positive integer).

    Glib::Ex::ConnectProperties->new
      ([$job,    'have-help-available'],
       [$dialog, 'response-sensitive#help', write_only => 1]);

Response sensitivity can always be written (it uses
C<set_response_sensitive>) and often write-only is all that's needed.  The
C<write_only> option can force that, as described above (L</General
Options>).

Response sensitivity is readable if C<get_response_for_widget> is
available, which means Gtk 2.8 up for Dialog, and not at all for InfoBar
as of Gtk 2.22.  Also, sensitivity is only applied to the C<sensitive>
property of the action area widgets, it's not recorded in the dialog as
such.  This means to be readable there must be at least one button (etc)
using the response.  ConnectProperties currently also assumes the first
widget it finds for the response will not be removed.  Perhaps this will
be relaxed in the future, but probably only as an option since response
buttons are not usually changed and noticing it needs extra signal
listening.
