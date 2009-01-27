# Copyright 2007, 2008, 2009 Kevin Ryde

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

package Glib::Ex::ConnectProperties;
use strict;
use warnings;
use Carp;
use Glib;
use List::Util;
use Scalar::Util;

our $VERSION = 4;

# set this to 1 for some diagnostic prints
use constant DEBUG => 0;

# The notify signal connections keep $self alive while the objects live.
# The only refs to the objects are weak ones in the $elem's.
#
# An alternative for the connection would be to have $elem in the userdata,
# and a ref from that elem to $self, with the array element for $elem
# weakened to avoid being circular.  Basically on a readable property the
# signal connection keeps $elem and $self alive, and on a non-readable it'd
# be the other way around with $self keeping $elem alive.  Is there any
# space saved by a 'self' entry $elem over a two-element array in the
# connection?

sub new {
  my ($class, @array) = @_;
  if (@array < 2) {
    croak 'Glib::Ex::ConnectProperties->new(): must have two or more object/property pairs';
  }

  foreach my $elem (@array) {
    my ($object, $pname, @params) = @$elem;
    my $pspec = $object->find_property ($pname)
      || croak "ConnectProperties: $object has no property '$pname'";

    # replacing element in @array
    $elem = { object => $object,
              pname  => $pname,
              @params };
  }
  my $self = bless { array => \@array }, $class;

  # make notify signal connections only after input validated
  foreach my $elem (@array) {
    my $object = $elem->{'object'};
    my $pname  = $elem->{'pname'};
    Scalar::Util::weaken ($elem->{'object'});

    my $pspec = $object->find_property ($pname);
    if ($pspec->get_flags & 'readable') {
      $elem->{'notify_id'} = $object->signal_connect
        ("notify::$pname", \&_do_notify, [ $self, $elem ]);
    }
  }

  # set initially from first readable, in case not already the same
  foreach my $elem (@array) {
    my $object = $elem->{'object'};
    my $pspec  = $object->find_property ($elem->{'pname'});
    if ($pspec->get_flags & 'readable') {
      _do_notify ($object, $pspec, [ $self, $elem ]);
      last;
    }
  }
  return $self;
}

#
# No DESTROY method.  No need to disconnect notify signals in DESTROY
# because each signal callback has a strong reference to the
# ConnectProperties object, meaning the only time a ConnectProperties is
# destroyed is when all the linked objects are destroyed, which means all
# the signals have been disconnected already.
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
  if (DEBUG) { my $from_pname = $from_pspec->get_name;
               print "_do_notify from $from_object/$from_pname";
               print " value ",$from_object->get_property ($from_pname);
               # print " for ",(defined $self ? $self : '[undef]');
               print $self->{'notify_in_progress'}
                 ? ' [already in progress]' : '';
               print "\n";
             }

  if ($self->{'notify_in_progress'}) { return; }
  local $self->{'notify_in_progress'} = 1;

  my $from_pname = $from_pspec->get_name;
  my $from_val = $from_object->get_property ($from_pname);
  if (DEBUG) { print "  propagate value ",
                 defined $from_val ? $from_val : 'undef', "\n"; }

  my $array = $self->{'array'};
  for (my $i = 0; $i < @$array; $i++) {
    my $to_elem = $array->[$i];
    if ($to_elem == $from_elem) { next; }  # not ourselves

    my $to_object = $to_elem->{'object'};
    if (! defined $to_object) {
      if (DEBUG) { print "  elem $i gone, dropping\n"; }
      splice @$array, $i, 1;
      $i--;
      next;
    }

    my $to_pname = $to_elem->{'pname'};
    my $to_pspec = $to_object->find_property ($to_pname);
    my $to_flags = $to_pspec->get_flags;
    ($to_flags & 'writable') || next;  # can't set

    my $to_val = $from_val;

    # clamp etc through $to_pspec
    # value_validate() wrapped in Glib 1.220, will remove the check when
    # ready to demand that version
    if (my $func = $to_pspec->can('value_validate')) {
      (undef, $to_val) = $func->($to_pspec, $to_val);
    }

    if ($to_flags & 'readable') {
      my $old_to_value = $to_object->get_property ($to_pname);
      if (_pspec_equal ($to_pspec, $old_to_value, $to_val)) {
        if (DEBUG) { print "  suppress equal to $to_object/$to_pname\n"; }
        next;
      }
    }

    if (DEBUG) { print "  store to $to_object/$to_pname\n"; }
    $to_object->set_property ($to_pname, $to_val);
  }
}

# Glib::Param::Boxed values_cmp is only by pointer value, so look for an
# 'equal' or 'compare' method on the value type.  Those methods probably
# won't like being passed undef (NULL) for the second arg, so guard against
# that.
#
# Gtk2::Gdk::Region and Gtk2::Gdk::Color have 'equal' (and GdkFont would too
# but it's not wrapped as of Gtk2 1.202).  Gtk2::TreePath has a 'compare'
# method.
#
# Only the exact pspec 'Glib::Param::Boxed' gets equal and compare methods,
# if you make a subclass for a particular flavour of boxed you should
# implement a values_cmp for everyone to use.
#
sub _pspec_equal {
  my ($pspec, $x, $y) = @_;

  if (ref $pspec eq 'Glib::Param::Boxed') {
    my $value_type = $pspec->get_value_type;
    if (my $func = $value_type->can('Glib_Ex_ConnectProperties_equal')) {
      return $func->($x, $y);
    }
    if (my $func = $value_type->can('equal')) {
      if (! defined $x || ! defined $y) {return ((defined $x) == (defined $y))}
      return $func->($x, $y);
    }
    if (my $func = $value_type->can('compare')) {
      if (! defined $x || ! defined $y) {return ((defined $x) == (defined $y))}
      return ($func->($x, $y) == 0);
    }
  }
  # values_cmp() wrapped in Glib 1.220, will remove the fallback when ready
  # to demand that version
  my $func = ($pspec->can('values_cmp')
              || $pspec->can('Glib_Ex_ConnectProperties_values_cmp')
              || croak 'ConnectProperties: oops, where\'s the values_cmp fallback?');
  return ($func->($pspec, $x, $y) == 0);
}

#------------------------------------------------------------------------------
# equality refinements for Glib::Param::Boxed
#
# This is just a Glib_Ex_ConnectProperties_equal() func added into the
# package of the applicable type.  Not a documented feature yet.  Might
# prefer paramspec subclasses offering a suitable values_cmp() which
# everyone could use, rather than special stuff here.

# Glib::ParamSpec->scalar just makes a Glib::Param::Boxed so values_cmp is
# by the SV address, which will be almost always different.  Try instead a
# compare by 'eq'.  It won't look into arrays etc, but you probably should
# setup a new ParamSpec type to make that happen properly.
#
sub Glib::Scalar::Glib_Ex_ConnectProperties_equal {
  my ($x, $y) = @_;
  if (! defined $x || ! defined $y) { return ((defined $x) == (defined $y)) }
  return ($x eq $y);
}

# Glib::Strv at the perl level as arrayref of strings, or undef.
# In Gtk2::AboutDialog it's just a Glib::Param::Boxed, compare by value.
#
# undef is not equal to an empty array, the same as GParamSpecValueArray has
# NULL not equal to a zero length array in param_value_array_values_cmp().
# There's probably no difference in actual use though ...
#
sub Glib::Strv::Glib_Ex_ConnectProperties_equal {
  my ($x, $y) = @_;
  if (! defined $x || ! defined $y) { return ((defined $x) == (defined $y)); }
  if (@$x != @$y) { return 0; }
  foreach my $i (0 .. $#$x) {
    if ($x->[$i] ne $y->[$i]) { return 0; }
  }
  return 1;
}

# Gtk2::Gdk::Cursor, by type, with possibly undef
#
sub Gtk2::Gdk::Cursor::Glib_Ex_ConnectProperties_equal {
  my ($x, $y) = @_;
  if (! defined $x || ! defined $y) { return ((defined $x) == (defined $y)); }

  my $xtype = $x->type;
  if ($xtype eq 'cursor-is-pixmap') {
    return $x == $y;  # can't look into pixmap contents
  } else {
    return $xtype eq $y->type;  # standard cursors by type
  }
}

# Gtk2::Border at the perl level is a hashref of fields, or undef.
# In Gtk2::Entry it's just a Glib::Param::Boxed, compare here by values.
# Apart from Gtk2::Entry it's thankfully rare.
#
sub Gtk2::Border::Glib_Ex_ConnectProperties_equal {
  my ($x, $y) = @_;
  if (! defined $x || ! defined $y) { return ((defined $x) == (defined $y)); }
  
  return ($x->{'left'}      == $y->{'left'}
          && $x->{'right'}  == $y->{'right'}
          && $x->{'top'}    == $y->{'top'}
          && $x->{'bottom'} == $y->{'bottom'});
}

#------------------------------------------------------------------------------
# values_cmp fallback

if (! Glib::ParamSpec->can('values_cmp')) {
  
  # overall fallback: integers, characters by number; Glib::Object's by ref;
  # Glib::Boxed by value (fairly useless most of the time)
  *Glib::ParamSpec::Glib_Ex_ConnectProperties_values_cmp = sub {
    my ($pspec, $x, $y) = @_;
    if (! defined $x || ! defined $y) { return ((defined $x) <=> (defined $y))}
    return ($x <=> $y);
  };
  
  # string and enum by alphabetical
  # no Glib::Param::GType since values_cmp() exists whenever that one will ...
  *Glib::Param::String::Glib_Ex_ConnectProperties_values_cmp
    = *Glib::Param::Enum::Glib_Ex_ConnectProperties_values_cmp
      = sub {
        my ($pspec, $x, $y) = @_;
        if (! defined $x || ! defined $y) {
          return ((defined $x) <=> (defined $y));
        }
        return ($x cmp $y);
      };
  
  # bools allowing any 0, '', undef
  *Glib::Param::Boolean::Glib_Ex_ConnectProperties_values_cmp = sub {
    my ($pspec, $x, $y) = @_;
    return ((! $x) <=> (! $y));
  };
  
  # double following epsilon
  *Glib::Param::Double::Glib_Ex_ConnectProperties_values_cmp = sub {
    my ($pspec, $x, $y) = @_;
    my $epsilon = $pspec->get_epsilon;
    if ($x < $y) {
      return -($y-$x > $epsilon);
    } else {
      return ($x-$y > $epsilon);
    }
  };
  
  # float truncated to single precision before comparing, and following epsilon
  *Glib::Param::Float::Glib_Ex_ConnectProperties_values_cmp = sub {
    my ($pspec, $x, $y) = @_;
    ($x, $y) = unpack 'f2', pack ('f2', $x, $y);
    my $epsilon = $pspec->get_epsilon;
    if ($x < $y) {
      return -($y-$x > $epsilon);
    } else {
      return ($x-$y > $epsilon);
    }
  };
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
more C<Glib::Object>s (including Gtk2 widgets) so a change made to any one
of them is propagated to the others.

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

=head2 Property Types

String, number, enum, flags, and object properties are supported.  Some
boxed types like C<Gtk2::Gdk::Color> work too, but others have problems (see
L</IMPLEMENTATION NOTES> below).

Read-only properties can be used.  They're read and propagated, but changes
in other linked properties are not stored back.  This can leave different
values, which rather defeats the purpose of the linkage.  Linking a
read-only probably only makes sense if the read-only one is the only one
changing.

Write-only properties can be used.  Nothing is read out of them, they're
just set from changes in the other linked properties.  (Write-only
properties are often pseudo "add" methods etc, so it's probably unlikely
linking a write-only will do much good.)

It works to connect two properties on the same object; doing so can ensure
they update together.  It also works to have two different ConnectProperties
with an object/property in common; a change coming from one group propagates
through to the other just fine.  In fact such a setup arises quite naturally
if you've got two controls for the same target; neither needs to know the
other exists.

=head2 Values

Before storing a value it's put through C<value_validate> on the target
ParamSpec (in Glib-Perl 1.220 where that method is available).  This for
instance clamps numbers which might be out of range, etc.  This may not be
quite right, but at least lets the target get close.

In the future the intention is to have some "map" options or transformation
functions on a per object+property basis, allowing for example a boolean to
become a strings, or enum values to be changed around, etc.

=head1 FUNCTIONS

=over 4

=item C<< $conn = Glib::Ex::ConnectProperties->new ([$obj1,$prop1], [$obj,$prop2], ...) >>

Connect two or more given object+property combinations.  Each argument is an
arrayref with an object and a property name.  For example

    $conn = Glib::Ex::ConnectProperties->new
                ([$aa_object, 'one-prop'],
                 [$bb_object, 'another-prop']);

The return value is a Perl object of type C<Glib::Ex::ConnectProperties>.
You can keep that to later break the connection explicitly with
C<disconnect> below, or otherwise you can ignore it.

An initial value is propagated from the first object+property (or the first
with a readable flag) to set all the others, in case they're not already the
same.  So put the object with the right initial value first.

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
have an infinite loop.  The present strategy is twofold

=over 4

=item *

An "in progress" flag in the ConnectProperties object, so during an update
it recognises any further C<notify> emissions as its own doing and can be
ignored.

=item *

On each target the value from a C<get> is compared before doing a C<set>.
If it's already what's wanted then the C<set> call is not made at all.

=back

The in-progress flag acts against immediate further C<notify>s.  They could
be avoided by disconnecting or blocking the respective handlers temporarily,
but that seems more work than ignoring.

The compare-before-set copes with C<freeze_notify>, because in that case the
C<notify> calls don't come while the "in progress" flag is on, only later,
perhaps a long time later.

It might be wondered if something simpler is possible, and the short answer
is that for the general case, not really.  The specific C<set_foo> methods
on most widgets and objects will skip an unchanged setting, but alas when
using the generic C<set_property> the protection above is needed.

=head2 Equality

An existing value and prospective new value for a property above are
compared using C<values_cmp> in Glib-Perl 1.220 (or a fallback otherwise).
ParamSpec subclasses can thus control what they consider equal.  For example
for floats anything within "epsilon" (1e-30 by default) is close enough.

The core C<Glib::Param::Boxed> only compares by pointer value, which is
fairly useless because boxed objects are copied so you hardly ever see an
identical pointer.  ConnectProperties tries to improve this by: Using an
C<equal> or C<compare> method from the value type, when available
(eg. C<Gtk2::Gdk::Color>).  Using C<eq> on C<Glib::Scalar>, which may be of
limited help.  (Subclassing the scalar ParamSpec and giving a new
C<values_cmp> is probably much better, if/when it's possible.)  And using
special code on C<Glib::Strv> and C<Gtk2::Border> by content, and
C<Gtk2::Gdk::Cursor> by C<type> (but bitmap cursors are still by pointer).

Potentially a C<Glib::Param::Object> pspec could benefit from C<equal> or
C<compare> method on the value type, letting object classes say how their
contents can be compared.  For now that's not done, since none of the core
types have such methods, and since like C<Glib::Scalar> it may be better as
a C<values_cmp> in a ParamSpec subclass, letting both C and Perl code know
how to compare.

=head2 Notifies

Incidentally, if you're writing a widget don't forget you have to explicitly
C<notify> if changing a property from anywhere outside your C<SET_PROPERTY>
method.  Duplicate notifies from within that method are ok and are collapsed
to just one emission at the end.  Of course this is required for any widget,
but failing to do will mean in particular that ConnectProperties won't work.

=head1 SEE ALSO

L<Glib::Object>

=head1 HOME PAGE

L<http://www.geocities.com/user42_kevin/glib-ex-connectproperties/>

=head1 LICENSE

Copyright 2007, 2008, 2009 Kevin Ryde

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
