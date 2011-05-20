# Copyright 2010, 2011 Kevin Ryde

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

package Glib::Ex::ConnectProperties::Element::child;
use 5.008;
use strict;
use warnings;
use Carp;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 16;

# uncomment this to run the ### lines
#use Smart::Comments;

sub check_property {
  my ($self) = @_;
  ### Element-child check_property()

  # check find_child_property() method exists now rather than a slew of
  # errors from later when attempting to set
  Gtk2::Container->can('find_child_property') # wrapped in Perl-Gtk2 1.240
      || croak 'ConnectProperties: No Gtk2::Container find_child_property() in this Perl-Gtk';

  # and that the property exists initially
  $self->SUPER::check_property;
}

# base is_readable() / is_writable() are true if no find_property() pspec
# always read/write in case no parent or no such property.  But for now
# demanding the widget be in a parent with the property initially.
#
# use constant is_readable => 1;
# use constant is_writable => 1;

sub find_property {
  my ($self) = @_;
  ### Element-child find_property()
  my $parent;
  return (($parent = $self->{'object'}->get_parent)
          && $parent->find_child_property ($self->{'pname'}));
}

sub read_signals {
  my ($self) = @_;
  return ('child-notify::' . $self->{'pname'});
}

sub get_value {
  my ($self) = @_;
  ### Element-child get_value(): $self->{'pname'}
  ### parent: $self->{'object'}->get_parent
  my $object = $self->{'object'};
  my $parent;
  return (($parent = $object->get_parent)
          && $parent->child_get_property ($object, $self->{'pname'}));
}
sub set_value {
  my ($self, $value) = @_;
  ### Element-child set_value(): $self->{'pname'}, $value
  ### parent: $self->{'object'}->get_parent
  my $object = $self->{'object'};
  if (my $parent = $object->get_parent) {
    $parent->child_set_property ($object, $self->{'pname'}, $value);
  }
}

1;
__END__
