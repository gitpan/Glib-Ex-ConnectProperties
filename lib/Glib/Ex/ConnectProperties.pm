# Copyright 2007, 2008 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.

package Glib::Ex::ConnectProperties;
use strict;
use warnings;
use Carp;
use Glib;
use List::Util;
use Scalar::Util;

our $VERSION = 3;

# set this to 1 for some diagnostic prints
use constant DEBUG => 0;

sub new {
  my ($class, @array) = @_;
  if (@array < 2) {
    croak 'Glib::Ex::ConnectProperties->new(): must have two or more object/property pairs';
  }

  foreach my $elem (@array) {
    my ($object, $property, @params) = @$elem;
    my $pspec = $object->find_property ($property)
      or croak "ConnectProperties: $object has no property \"$property\"";

    # replacing element in @array
    $elem = { object   => $object,
              property => $property,
              equal    => _pspec_equality_func($pspec),
              flags    => $pspec->{'flags'},
              @params };
    Scalar::Util::weaken ($elem->{'object'});
  }
  my $self = bless { array => \@array }, $class;

  # make notify connections only after input validated
  foreach my $elem (@array) {
    my $object   = $elem->{'object'};
    my $property = $elem->{'property'};

    if ($elem->{'flags'} & 'readable') {
      $elem->{'notify_id'} = $object->signal_connect
        ("notify::$property", \&_do_notify, [ $self, $elem ]);
    }
  }

  # set initially from first, in case not already the same
  my $elem = $array[0];
  my $object = $elem->{'object'};
  my $property = $elem->{'property'};
  my $pspec = $object->find_property ($property);
  _do_notify ($object, $pspec, [ $self, $elem ]);
  return $self;
}

#
# No DESTROY method here.  No need to disconnect notify signals in DESTROY
# because each signal callback has a strong reference to the
# ConnectProperties object, meaning the only time a ConnectProperties is
# destroyed is when all the linked objects are destroyed, and in that case
# all the signals have been disconnected already.
#

sub disconnect {
  my ($self) = @_;
  my $array = $self->{'array'};
  if (DEBUG) { print "$self disconnect ",scalar(@$array)," elems\n"; }

  while (my $elem = pop @$array) {
    my $object = $elem->{'object'} || next; # if not gone due to weakening
    if (DEBUG) { print "  $object id ",$elem->{'notify_id'}||'undef',"\n"; }

    my $id = $elem->{'notify_id'};
    if (! $id) { next; } # no connection on write-only properties

    # guard against already disconnected during perl "global destruction",
    # signal_handler_disconnect() will print an unsightly g_warn() if $id is
    # already gone
    if ($object->signal_handler_is_connected ($id)) {
      $object->signal_handler_disconnect ($id);
    }
  }
}

# 'notify' signal from a connected object
sub _do_notify {
  my ($from_object, $from_pspec, $userdata) = @_;
  my ($self, $from_elem) = @$userdata;
  if (DEBUG) { print "$self notify from $from_object/";
               my $from_property = $from_pspec->get_name;
               print "$from_property value ";
               print $from_object->get_property ($from_property);
               print $self->{'notify_in_progress'}?' [already in progress]':'';
               print "\n";}

  if ($self->{'notify_in_progress'}) { return; }
  local $self->{'notify_in_progress'} = 1;

  my $from_property = $from_pspec->get_name;
  my $from_val = $from_object->get_property ($from_property);
  if (DEBUG) { print "  propagate value ",
                 defined $from_val ? $from_val : 'undef', "\n"; }

  my $array = $self->{'array'};
  for (my $i = 0; $i < @$array; $i++) {
    my $to_elem = $array->[$i];
    if ($to_elem == $from_elem) { next; }  # not ourselves
    if (! ($to_elem->{'flags'} & 'writable')) { next; }  # can't set

    my $to_object = $to_elem->{'object'};
    if (! defined $to_object) {
      if (DEBUG) { print "  elem $i gone, dropping\n"; }
      splice @$array, $i, 1;
      $i--;
      next;
    }

    my $to_val = $from_val;
    my $to_property = $to_elem->{'property'};

    if ($to_elem->{'flags'} & 'readable') {
      my $old_to_value = $to_object->get_property ($to_property);
      if ($to_elem->{'equal'}->($old_to_value, $to_val)) {
        if (DEBUG) { print "  suppress equal to $to_object/$to_property\n"; }
        next;
      }
    }

    if (DEBUG) { print "  store to $to_object/$to_property\n"; }
    $to_object->set ($to_property, $to_val);
  }
}

# _pspec_equality_func() returns a coderef which can be called to test the
# equality of two values from $pspec (Glib::ParamSpec) properties.
#
# The quantity of code below is pretty unattractive.  Isn't there something
# builtin for testing equality between "GValue"s or "GParamSpec" flavoured
# values?  The code is also fairly excessive for the present straight
# copying between properties, but if there's transformations applied in the
# future it'll matter more.
#
sub _pspec_equality_func {
  my ($pspec) = @_;
  my $type = $pspec->get_value_type;

  return ($type->can('equal') && \&_eq_method_equal)
      || ($type->can('compare') && \&_eq_method_compare)
      || $type->can('Glib_Ex_ConnectProperties_equal')
      || $pspec->can('Glib_Ex_ConnectProperties_equal')
      || croak "ConnectProperties: oops, where's the ParamSpec equality fallback?";
}

# 'equal' or 'compare' methods can't be called through 'undef' of course,
# and assume the methods won't like getting undef as their second arg
# either.
#
# Gtk2::Gdk::Region and Gtk2::Gdk::Color have 'equal' methods.
# Gtk2::TreePath has a 'compare' method.
#
# The old style Gtk2::Gdk::Font is not wrapped as of Gtk2-Perl 1.181, but
# it's got a gdk_font_equal() to hit here too, if it were.
#
# Any types using overloads can probably use the fallback "==" code, these
# funcs are for types without overloads.
#
sub _eq_method_equal {
  my ($a, $b) = @_;
  if (! defined $a && ! defined $b) { return 1; }
  if (! (defined $a && defined $b)) { return 0; }
  return $a->equal ($b);
}
sub _eq_method_compare {
  my ($a, $b) = @_;
  if (! defined $a && ! defined $b) { return 1; }
  if (! (defined $a && defined $b)) { return 0; }
  return $a->compare($b) == 0;
}

# The default equal using "=="
#    - numbers numerically
#    - Glib::Flags overloaded == operator
#    - Glib::Object by perl ref used numerically
#
# Note this bombs badly on Glib::Boxed, which generally gets copied around
# so you never see the same pointer twice :-(
#
sub Glib::ParamSpec::Glib_Ex_ConnectProperties_equal {
  my ($a, $b) = @_;
  if (! defined $a && ! defined $b) { return 1; }
  if (! (defined $a && defined $b)) { return 0; }
  return $a == $b;
}

sub Glib::Param::Boolean::Glib_Ex_ConnectProperties_equal {
  my ($a, $b) = @_;
  return (($a && $b) || (! $a && ! $b));
}

# Glib::Float truncated to single precision before comparing.
#
# "Glib::Float" isn't an actual perl class (as of Gtk2-Perl 1.181), so must
# set this up through Glib::Param::Float.
#
sub Glib::Param::Float::Glib_Ex_ConnectProperties_equal {
  my ($a, $b) = @_;
  ($a, $b) = unpack 'f2', pack ('f2', $a, $b);
  return $a == $b;
}

# Glib::Enum values as nick strings.
#
# "Glib::Enum" isn't an actual perl class in Gtk2-Perl 1.181 (though is
# going to become one in the future), so must set this up through
# Glib::Param::Enum.
#
sub Glib::Param::Enum::Glib_Ex_ConnectProperties_equal {
  my ($a, $b) = @_;
  return $a eq $b;
}

sub Glib::String::Glib_Ex_ConnectProperties_equal {
  my ($a, $b) = @_;
  if (! defined $a && ! defined $b) { return 1; }
  if (! (defined $a && defined $b)) { return 0; }
  return $a eq $b;
}

# Same 'eq' compare on scalars as done for strings, though that may or may
# not do what you actually want.
#
*Glib::Scalar::Glib_Ex_ConnectProperties_equal
  = \&Glib::String::Glib_Ex_ConnectProperties_equal;

# Glib::Strv arrayref of strings, or undef
# This occurs in Gtk2::AboutDialog, but is otherwise a bit rare.
#
sub Glib::Strv::Glib_Ex_ConnectProperties_equal {
  my ($a, $b) = @_;
  $a ||= [];
  $b ||= [];
  if (@$a != @$b) { return 0; }
  foreach my $i (0 .. $#$a) {
    if ($a->[$i] ne $b->[$i]) { return 0; }
  }
  return 1;
}

# Gtk2::Gdk::Cursor, possibly undef
#
sub Gtk2::Gdk::Cursor::Glib_Ex_ConnectProperties_equal {
  my ($a, $b) = @_;
  if (! defined $a && ! defined $b) { return 1; }
  if (! (defined $a && defined $b)) { return 0; }

  my $atype = $a->type;
  if ($atype eq 'cursor-is-pixmap') {
    return $a == $b;  # can't look into pixmap contents
  } else {
    return $atype eq $b->type;  # standard cursors by type
  }
}

# Gtk2::Border hashref of fields, or undef.
# This occurs in Gtk2::Entry, but is otherwise thankfully rare.
#
sub Gtk2::Border::Glib_Ex_ConnectProperties_equal {
  my ($a, $b) = @_;
  if (! defined $a && ! defined $b) { return 1; }
  if (! (defined $a && defined $b)) { return 0; }
  return ($a->{'left'} == $b->{'left'}
          && $a->{'right'} == $b->{'right'}
          && $a->{'top'} == $b->{'top'}
          && $a->{'bottom'} == $b->{'bottom'});
}

1;
__END__

=head1 NAME

Glib::Ex::ConnectProperties -- link properties between objects

=head1 SYNOPSIS

 use Glib::Ex::ConnectProperties;
 my $conn = Glib::Ex::ConnectProperties->new ([$check,'active'],
                                              [$widget,'visible']);

 $conn->disconnect;   # explicit disconnect

=head1 DESCRIPTION

C<Glib::Ex::ConnectProperties> links together specified properties on two or
more C<Glib::Object>s (including Gtk widgets) so a change made to any one of
them is propagated to the others.

This is an easy way to tie a user control widget to a setting elsewhere.
For example a CheckButton C<active> could be linked to the C<visible> of
another widget, letting the user click to hide or show it.

      +--------------------+             +-------------+
      | CheckButton/active |  <------->  | Foo/visible |
      +--------------------+             +-------------+

The advantage of ConnectProperties is that it's bi-directional, so if other
code changes "Foo/visible" then that change is sent to "CheckButton/active"
too, ensuring the button display is up-to-date with what it's controlling,
no matter how the target changes.

=head2 Property types

String, number, enum, flags, and object properties are supported.  Some
boxed types like C<Gtk2::Gdk::Color> work too, but others have potential
problems (see L</IMPLEMENTATION NOTES> below).

Read-only properties can be used.  They're read and propagated, but changes
in other linked properties are not stored to read-onlys; though this leaves
different values, rather defeating the purpose of the linkage.  Linking a
read-only probably only makes sense if the read-only one is the only one
changing.

Write-only properties can be used.  Nothing is read out of them, they're
just set from changes in the other linked properties.  (Write-only
properties are often pseudo "add" methods etc, so it's probably unlikely
linking in a write-only will do much good.)

It works to connect two properties on the same object; doing so can ensure
they update together.  It also works to have two different ConnectProperties
with an object/property in common; a change coming from one group propagates
through to the other just fine.  In fact such a setup arises quite naturally
if you've got two controls for the same target; neither of them needs to
know the other exists.

Currently there's no transformations applied to values copied between
property settings.  The intention is to have some "map" options or
transformation functions on a per object+property basis.

=head1 FUNCTIONS

=over 4

=item C<< $conn = Glib::Ex::ConnectProperties->new ([$obj1,$prop1],[$obj,$prop2],...) >>

Connect two or more given object+property combinations.  Each argument is an
array ref to an object and a property name.  For example

    $conn = Glib::Ex::ConnectProperties->new
                ([$first_object, 'first-property-name'],
                 [$second_object, 'second-property-name']);

The return value is a Perl object of type C<Glib::Ex::ConnectProperties>.
You can keep that to later break the connection explicitly with
C<disconnect> below, or otherwise you can ignore it.

A ConnectProperties linkage lasts as long as the linked objects exist, but
it only keeps weak references to those objects, so the linkage doesn't
prevent some or all of them being garbage collected.

=item C<< $conn->disconnect() >>

Disconnect the given ConnectProperties linkage.

=back

=head1 IMPLEMENTATION NOTES

ConnectProperties uses a C<notify> signal handler on each object to update
the others.  Updating those others makes them in turn emit further C<notify>
signals (even if the value is unchanged), so some care must be taken not to
cause an infinite loop.  The present strategy for that is twofold

=over 4

=item *

An "in progress" flag in the ConnectProperties object, so during an update
any further C<notify> emissions are recognised as its own doing and can be
ignored.

=item *

The value from a C<get> is compared before doing a C<set>.  If it's already
what's wanted then the C<set> call is not made at all.

=back

The in-progress flag is effective against immediate further C<notify>s.
They could also be avoided by disconnecting or blocking the respective
handlers temporarily, but that'd probably take more bookkeeping work than
just ignoring.

The compare-before-set is essential to cope with C<freeze_notify>, because
in that case the C<notify> calls don't come while the "in progress" flag is
on, only later, perhaps a long time later.

It might be wondered if something simpler is possible, and the short answer
is that for the general case, not really.  The specific C<set_foo> methods
on most widgets and objects will skip an unchanged setting, but alas when
using the generic C<set_property> the protection above is needed.

=head2 Equality

Glib-Perl doesn't yet wrap C<values_cmp> to do an "equal" test of arbitrary
property values for the compare-before-set.  ConnectProperties recognises
the types noted above, and can use an object C<equal> or C<compare> method
at the Perl level like boxed types C<Gtk2::Gdk::Region> and
C<Gtk2::TreePath> have.  (Boxed types get copied so unfortunately you don't
see the same pointer twice, let alone the same Perl ref, making a direct
C<< == >> no good.)

=head2 Notifies

Incidentally, if you're writing a widget don't forget you have to explicitly
C<notify> if changing a property from anywhere outside your C<SET_PROPERTY>
method.  (Duplicate notifies from within that method are ok and are
collapsed to just one emission at the end.)  Of course this is required for
any widget, but failing to do will mean in particular that ConnectProperties
won't work.

=head1 SEE ALSO

L<Glib::Object>

=head1 HOME PAGE

L<http://www.geocities.com/user42_kevin/glib-ex-connectproperties/>

=head1 LICENSE

Copyright 2007, 2008 Kevin Ryde

Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ConnectProperties.  If not, see L<http://www.gnu.org/licenses/>.

=cut
