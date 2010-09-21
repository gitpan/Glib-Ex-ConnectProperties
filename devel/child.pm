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

package Glib::Ex::ConnectProperties::Element::child;
use 5.008;
use strict;
use warnings;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 10;

# uncomment this to run the ### lines
#use Smart::Comments;


# no check
use constant check_property => undef;


# Gtk2::Container has child_get_property(), child_set_property()
#
# Goo::Canvas::Item has get_child_properties() / set_child_properties(), and
# in Goo::Canvas 0.06 only the plurals wrapped, not singular
# get_child_property() / set_child_property()
#
sub get_value {
  my ($self) = @_;
  ### ConnectProperties-Child get_value(): $self->{'pname'}
  ### parent: $self->{'object'}->get_parent
  my $object = $self->{'object'};
  my $parent;
  return (($parent = $object->get_parent)
          && do {
            my $method = ($parent->can('get_child_properties')
                          || 'child_get_property');
            $parent->$method ($object, $self->{'pname'})
          });
}
sub set_value {
  my ($self, $value) = @_;
  ### ConnectProperties-Child set_value(): $self->{'pname'}, $value
  my $object = $self->{'object'};
  if (my $parent = $object->get_parent) {
    my $method = $parent->can('set_child_properties') || 'child_set_property';
    ### $parent
    ### $method
    $parent->$method ($object, $self->{'pname'}, $value);
  }
}

# always read/write in case not a child yet
use constant is_readable => 1;
use constant is_writable => 1;

sub find_property {
  my ($self) = @_;
  my $parent;
  my $coderef;
  return (($parent = $self->{'object'}->get_parent)
          && ($coderef = $parent->can('find_child_property'))
          && $parent->$coderef ($self->{'pname'}));
}

sub read_signal {
  my ($self) = @_;
  return ('child-notify::' . $self->{'pname'},
          'parent-set');
}

1;
__END__
