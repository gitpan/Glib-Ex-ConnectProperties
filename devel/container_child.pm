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

package Glib::Ex::ConnectProperties::Element::container_child;
use 5.008;
use strict;
use warnings;
use Carp;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 12;

# uncomment this to run the ### lines
#use Smart::Comments;

sub check_property {
  # my ($self) = @_;
  ### Element-child check_property()

  # check this initially rather than a slew of errors from find_property()
  # later when attempting to set
  Gtk2::Container->can('find_child_property')
      || croak 'ConnectProperties: No Gtk2::Container find_child_property() in this Perl-Gtk';
}

# always read/write in case no parent or no such property
use constant is_readable => 1;
use constant is_writable => 1;

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
  # 'parent-set'
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








# =head2 Container Child Properties
# 
# C<Gtk2::Container> classes define "child properties" which exist on a widget
# when it's the child of a particular type of container.  For example
# C<Gtk2::Table> has attachment positions and options as child properties.
# These are separate from a widget's normal object properties.
# 
# Child properties can be used from ConnectProperties in Gtk2-Perl 1.240 and
# higher (where C<find_child_property> is available).  The property names are
# "container-child#top-attach" etc on the child widget.
# 
#     Glib::Ex::ConnectProperties->new
#       ([$adj,         'value'],
#        [$childwidget, 'container-child#bottom-attach']);
# 
# Currently C<$childwidget> should have a parent with the given child
# property.  If it's unparented later then nothing is read from or written to
# it.
# 
# If C<$childwidget> is reparented then it's currently unspecified what will
# happen.  Perhaps it should behave like an initial connection creation and
# write to it from the first readable.  Perhaps if it's the first readable
# then propagate its current value out.  Noticing a reparent requires the
# C<parent-set> signal, so perhaps an option could say whether that might be
# needed, so save setting that when not needed.




# "container-child#top-attach"
# 
# "goo-child#top-attach"
# "child#top-attach"


