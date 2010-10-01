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

our $VERSION = 11;

# uncomment this to run the ### lines
#use Smart::Comments;


# no check
use constant check_property => undef;

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

sub read_signals {
  my ($self) = @_;
  return ('child-notify::' . $self->{'pname'},
          'parent-set');
}

# Gtk2::Container has child_get_property(), child_set_property()
#
# Goo::Canvas::Item has get_child_properties() / set_child_properties(), and
# in Goo::Canvas 0.06 only the plurals wrapped, not the singular names
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

1;
__END__





# =head2 Child Properties
# 
# C<Gtk2::Container> defines "child properties" which are attributes of a
# widget when it's the child of a particular container class.  For example
# C<Gtk2::Table> has attachment points and options for each child.  These
# are separate from a widget's normal object properties.
#
# Child properties can be accessed from ConnectProperties in Gtk2-Perl 1.240
# under a property name like "child#top-attach" on a child widget.
# 
#     Glib::Ex::ConnectProperties->new
#       ([$childwidget, 'child#bottom-attach'],
#        [$adj,         'value']);
#
# The case where a widget has a parent and doesn't change is clear, it's
# just a property with C<child_set_property> etc for getting and setting.
# But it's not yet settled what should happen if a child widget changes
# parent, or doesn't yet have a parent, or gets a parent without the
# property name in question.
#
# Currently when a widget has no parent it's considered not readable and not
# writable so is ignored until it gets a parent.  Getting a new parent is
# treated like the ConnectProperties C<new>, meaning the first readable is
# propagated to the child setting, or if the child setting is first then
# from it to the other elements.  Don't rely on this.  It will probably
# change.  Perhaps C<undef> on no parent would be better.
