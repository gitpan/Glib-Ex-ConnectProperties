# no signal for child added, emission of parent-set only



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

package Glib::Ex::ConnectProperties::Element::container;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Scalar::Util;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 11;

# uncomment this to run the ### lines
#use Smart::Comments;


# container-children#empty
# container-children#non-empty
# container-children#count
# container-children#top-count

# my $conn = Glib::Ex::ConnectProperties->new
#   ([$menu,   'container-children#non-empty' ],
#    [$button, 'sensitive']);


my %pspecs = do {
  # dummy name as paramspec name cannot be empty string
  my $pspec = Glib::ParamSpec->boolean ('c', # name
                                        'c', # name
                                        '',  # blurb
                                        0,   # default
                                        ['readable']);
  ('empty'     => $pspec,
   'non-empty' => $pspec)
};
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

my $parent_set_id;
my $instance_count = 0;
sub new {
  $parent_set_id ||= Gtk2::Widget->signal_add_emission_hook
    (parent_set => \&_do_parent_set_emission);

  my $self = shift->SUPER::new(@_);
  $self->{'empty'} = ! ($self->{'object'}->get_children)[0]; # initially
  Scalar::Util::weaken ($self->{'object'}->{'Glib_Ex_ConnectProperties'}->{$self+0} = $self);
  return $self;
}

sub DESTROY {
  my ($self) = @_;
  if (my $object = $self->{'object'}) {
    my $href = $object->{'Glib_Ex_ConnectProperties'};
    delete $href->{$self+0};
    if (! %$href) {
      delete $object->{'Glib_Ex_ConnectProperties'};
    }
  }
  if (! --$instance_count) {
    Gtk2::Widget->signal_remove_emission_hook ($parent_set_id);
    undef $parent_set_id;
  }
}

use constant read_signals => ();

sub _do_parent_set_emission {
  my ($invocation_hint, $param_list) = @_;
  my ($widget, $parent) = @$param_list;

  if ($parent) {
    foreach my $self (@{$parent->{'Glib_Ex_ConnectProperties'}}) {
      if ($self->{'empty'}) {
        $self->{'empty'} = 0;
        Glib::Ex::ConnectProperties::_do_read_handler ($self);
      }
    }
  }
}

sub get_value {
  my ($self) = @_;
  return ($self->{'empty'} ^ ($self->{'pname'} eq 'non-empty'));
}
sub set_value {
  die "oops, container-children is meant to be read-only";
}

1;
__END__
