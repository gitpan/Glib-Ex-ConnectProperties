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

our $VERSION = 14;

# uncomment this to run the ### lines
#use Smart::Comments;

my $get_widget_for_response
  = (Gtk2::Dialog->can('get_widget_for_response') # new in Gtk 2.20
     ? 'get_widget_for_response'
     : do {
       require List::Util;
       sub {
         my ($dialog, $response) = @_;
         return List::Util::first {$dialog->get_response_for_widget($_)
                                     eq $response}
           $dialog->get_action_area->get_children;
       }
     });

my $pspec = Glib::ParamSpec->boolean ('sensitive',
                                      'sensitive',
                                      '', # blurb
                                      1,  # default
                                      Glib::G_PARAM_READWRITE);
my $pspec_writeonly = Glib::ParamSpec->boolean ('sensitive',
                                                'sensitive',
                                                '', # blurb
                                                1,  # default
                                                'writable');

# cf g_enum_get_value_by_nick
# sub _enum_get_value_by_nick {
#   my ($enum_class, $nick) = @_;
#   return List::Util::first {$nick eq $_->{'nick'}}
#     Glib::Type->list_values($enum_class);
# }
# sub _enum_get_value_by_name {
#   my ($enum_class, $name) = @_;
#   return List::Util::first {$name eq $_->{'name'}}
#     Glib::Type->list_values($enum_class);
# }
# return info hash { nick=>,name=>,value=> } representing GEnumValue, or undef
sub _enum_get_value_by_perl {
  my ($enum_class, $str) = @_;
  return List::Util::first {$str eq $_->{'nick'}
                              || $str eq $_->{'name'}}
    Glib::Type->list_values($enum_class);
}

sub find_property {
  my ($self) = @_;
  ### response-sensitive find_property(): $self->{'pname'}
  ### can(get_response_for_widget): $self->{'object'}->can('get_response_for_widget')
  my $pname = $self->{'pname'};
  my $object;
  return ((_enum_get_value_by_perl('Gtk2::ResponseType',$pname)
           || $pname =~ /^-?\d+$/)
          && ($self->{'object'}->can('get_response_for_widget')
              ? $pspec
              : $pspec_writeonly));
}

sub connect_signals {
  my ($self) = @_;
  my $pname = $self->{'pname'};
  my $button = $self->{'object'}->$get_widget_for_response($pname)
    || croak "No widget for response $pname";

  $self->{'ids'} = Glib::Ex::SignalIds->new
    ($button,
     $button->signal_connect ('notify::sensitive',
                              \&Glib::Ex::ConnectProperties::_do_read_handler,
                              $self));
}

sub get_value {
  my ($self) = @_;
  ### response-sensitive get_value(): $self->{'pname'}
  my $button;
  return (($button = $self->{'object'}->$get_widget_for_response($self->{'pname'}))
          ? $button->get('sensitive')
          : 1);
}
sub set_value {
  my ($self, $value) = @_;
  ### response-sensitive set_value(): $self->{'pname'}
  ### $value
  $self->{'object'}->set_response_sensitive ($self->{'pname'}, $value);
}

1;
__END__




# my %response_types;
# @response_types{map {($_->{'nick'}, $_->{'name'})}
#                   Glib::Type->list_values('Gtk2::ResponseType')} = ();

# sub _enum_value_is_valid {
#   my ($enum_class, $str) = @_;
#   foreach my $info (Glib::Type->list_values('Gtk2::ResponseType')) {
#     if ($str eq $_->{'nick'} || $str eq $_->{'name'}) {
#       return 1;
#     }
#   }
#   return 0;
# }

