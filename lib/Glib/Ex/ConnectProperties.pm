# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use List::Util;
use Scalar::Util;

our $VERSION = 7;

# uncomment this to run the ### lines
#use Smart::Comments;


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
    $object->find_property ($pname)
      or croak "ConnectProperties: $object has no property '$pname'";

    # replacing element in @array
    $elem = { object => $object,
              pname  => $pname,
              @params };
  }
  my $self = bless { array => \@array }, $class;

  # make notify signal connections only after input validated
  foreach my $elem (@array) {
    if (my $h = delete $elem->{'hash_in'}) {
      ### hash_in func: "@{[keys %$h]}"
      $elem->{'func_in'} = _make_hash_func ($h);
    }
    if (my $h = delete $elem->{'hash_out'}) {
      ### hash_out func: "@{[keys %$h]}"
      $elem->{'func_out'} = _make_hash_func ($h);
    }

    if (delete $elem->{'bool_not'}) {
      $elem->{'func_in'} =  $elem->{'func_out'} = \&_bool_not;
    }

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
  ### ConnectProperties disconnect: "$self ".scalar(@$array)." elems"

  while (my $elem = pop @$array) {
    my $object = $elem->{'object'} || next; # if not gone due to weakening
    ###   object: "$object id ".($elem->{'notify_id'}||'undef')

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
  ### ConnectProperties _do_notify: "$self $from_object/".$from_pspec->get_name
  ###   value: $from_object->get_property ($from_pspec->get_name)
  ###   notify_in_progress: $self->{'notify_in_progress'}

  if ($self->{'notify_in_progress'}) { return; }
  local $self->{'notify_in_progress'} = 1;

  my $from_pname = $from_pspec->get_name;
  my $from_val = $from_object->get_property ($from_pname);
  ###   propagate value: $from_val
  if (my $func = $from_elem->{'func_out'}) {
    $from_val = $func->($from_val);
    ###   func_out becomes: $from_val
  }

  my $array = $self->{'array'};
  for (my $i = 0; $i < @$array; $i++) {
    my $to_elem = $array->[$i];
    if ($to_elem == $from_elem) { next; }  # not ourselves

    my $to_object = $to_elem->{'object'};
    if (! defined $to_object) {
      ###   elem gone, dropping: $i
      splice @$array, $i, 1;
      $i--;
      next;
    }

    my $to_pname = $to_elem->{'pname'};
    my $to_pspec = $to_object->find_property ($to_pname);
    my $to_flags = $to_pspec->get_flags;

    # skip non-writable targets
    ($to_flags & 'writable') || next;

    my $to_val = $from_val;
    if (my $func = $to_elem->{'func_in'}) {
      $to_val = $func->($to_val);
      ###   func_in becomes: $to_val
    }

    # value_validate() to clamp $to_val for $to_pspec
    # value_validate() is wrapped in Glib 1.220, remove the check when ready
    # to demand that version
    if (my $func = $to_pspec->can('value_validate')) {
      (undef, $to_val) = $func->($to_pspec, $to_val);
    }

    # skip if target already contains $to_val, to avoid extra 'notify's
    if ($to_flags & 'readable') {
      my $old_to_val = $to_object->get_property ($to_pname);
      if (_pspec_equal ($to_pspec, $old_to_val, $to_val)) {
        ###   suppress already equal: "$to_object/$to_pname"
        next;
      }
    }

    ###   store to: "$to_object/$to_pname"
    $to_object->set_property ($to_pname, $to_val);
  }
}

sub _pspec_equal {
  my ($pspec, $x, $y) = @_;

  # Glib::Param::Boxed values_cmp() is only by pointer value, so try to do
  # better by looking for an equal() or compare() method on the value type.
  # This is only for the exact pspec 'Glib::Param::Boxed'.  If you make a
  # subclass for a flavour of boxed object you should implement a values_cmp
  # for everyone to use.
  #
  if (ref $pspec eq 'Glib::Param::Boxed') {
    my $value_type = $pspec->get_value_type;  # string class name

    if (my $func = $value_type->can('Glib_Ex_ConnectProperties_equal')) {
      return $func->($x, $y);
    }

    # Gtk2::Gdk::Region and Gtk2::Gdk::Color have 'equal' (and GdkFont would
    # too but it's not wrapped as of Gtk2 1.221).  Gtk2::TreePath has a
    # 'compare' method.  Those methods don't much like undef (NULL), and
    # presume that other similar methods won't either, so guard against
    # that.
    #
    if (my $func = $value_type->can('equal')) {
      if (! defined $x || ! defined $y) {
        return ((defined $x) == (defined $y)); # undef==undef, else not equal
      }
      return $func->($x, $y);
    }
    if (my $func = $value_type->can('compare')) {
      if (! defined $x || ! defined $y) {
        return ((defined $x) == (defined $y)); # undef==undef, else not equal
      }
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

sub _make_hash_func {
  my ($h) = @_;
  return sub { $h->{$_[0]} };
}
sub _bool_not {
  ! $_[0]
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

BEGIN {
  if (! Glib::ParamSpec->can('values_cmp')) {
    no warnings 'once';

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
}

1;
__END__

=head1 NAME

Glib::Ex::ConnectProperties -- link properties between objects

=for test_synopsis my ($check,$widget);

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
code changes "Foo/visible" then that change is sent back to
"CheckButton/active" too, ensuring the button display is up-to-date with
what it's controlling, no matter how the target changes.

=head2 Property Types

String, number, enum, flags, and object property types are supported.  Some
boxed types like C<Gtk2::Gdk::Color> work too, though others may not (see
L</Equality> below).

Read-only properties can be given.  They're propagated out to the other
linked properties but changes in those others are not stored back.  This can
leave different values, which rather defeats the purpose of the linkage.
Linking a read-only probably only makes sense if the read-only one is the
only one changing.

Write-only properties can be given.  Nothing is read out of them, they're
just set from changes in the other linked properties.  Write-only properties
are often pseudo "add" methods etc, so it's probably unlikely linking a
write-only will do much good.

It works to connect two properties on the same object; doing so can ensure
they update together.  It also works to have two different ConnectProperties
with an object/property in common; a change coming from one group propagates
through to the other.  Such a setup arises quite naturally if you've got two
controls for the same target; neither needs to know the other exists.

=head1 FUNCTIONS

=over 4

=item C<< $conn = Glib::Ex::ConnectProperties->new ([$obj1,$pname1], [$obj,$pname2], ...) >>

Connect two or more given object+property combinations.  Each argument is an
arrayref with an object and a property name.  For example

    $conn = Glib::Ex::ConnectProperties->new
                ([$aa_object, 'one-prop'],
                 [$bb_object, 'another-prop']);

The return value is a Perl object of type C<Glib::Ex::ConnectProperties>.
You can keep that to later break the connection explicitly using
C<disconnect> below, otherwise ignore it.

An initial value is propagated from the first object+property (the first
readable one) to set all the others in case they're not already the same.
So put the object with the desired initial value first.

A ConnectProperties linkage lasts as long as the linked objects exist.  It
only keeps weak references to those objects, so the linkage doesn't prevent
some or all of them being garbage collected.

=item C<< $conn->disconnect() >>

Disconnect the given ConnectProperties linkage.

=back

=head1 VALUE TRANSFORMATIONS

Before storing a value it's put through C<value_validate> on the target
ParamSpec (in Glib-Perl 1.220 where that method is available).  This clamps
numbers which might be out of range, might manipulate string contents, etc.
The result may not be quite right, but at least lets the target get close.

General value transformations can be specified with parameters in each
object/property element.  These transformation are applied before
C<value_validate>.  For example to negate a boolean property,

    Glib::Ex::ConnectProperties->new
        ([$checkbutton, 'active'],
         [$label, 'sensitive', bool_not => 1]);

The possible parameters are

=over

=item C<< bool_not => 1 >>

Negate with the Perl C<!> operator.

=item C<< func_in => $coderef >>

=item C<< func_out => $coderef >>

Call C<< $value = &$coderef($value) >> to transform values going in or
coming out.

=item C<< hash_in => $hashref >>

=item C<< hash_out => $hashref >>

Apply C<< $value = $hashref->{$value} >> to transform values going in or
coming out.

If a C<$value> doesn't exist in the hash then the result will be C<undef> in
the usual way.  Various tie modules can change that in creative wasy, for
example C<Hash::WithDefaults> to look in fallback hashes.

=back

For a read-only or write-only property only the corresponding out or in
transformation is needed.  For a read-write property the "in" should
generally be the inverse of "out".  Nothing is done to enforce that, but
strange things are likely to happen if the two are inconsistent.

Hashes are not copied, so future changes to their contents will be used by
the ConnectProperties, though there's nothing to forcibly update values if
the current settings might be affected.

=head1 IMPLEMENTATION NOTES

ConnectProperties uses a C<notify> signal handler on each object to update
the others.  Updating causes them to emit further C<notify> signals (even if
the value is unchanged), so some care must be taken not to have an infinite
loop.  The present strategy is twofold

=over 4

=item *

An "in progress" flag in the ConnectProperties object, so during an update
it recognises that any further C<notify> emissions as its own doing and can
be ignored.

=item *

On each target the value from a C<get> is compared before doing a C<set>.
If already right then the C<set> call is not made at all.

=back

The in-progress flag acts against immediate further C<notify>s.  Temporarily
disconnecting or blocking the handlers could do the same, but that seems
more work than ignoring.

The compare-before-set copes with C<freeze_notify> because in that case the
C<notify> calls don't come while the "in progress" flag is on, only later,
perhaps a long time later.

If the C<func_in> / C<func_out> transformations are inconsistent, so a value
going in is always different from what comes out, then usually the "in
progress" case prevents an infinite loop, so long as the program eventually
reaches a state with no C<freeze_notify>'s in force.

It might be wondered if something simpler is possible.  For the general case
alas no, not really.  The specific C<set_foo> methods on most widgets and
objects will often notice an unchanged setting and do nothing, but when
using the generic C<set_property> the protection above is needed.

=head2 Equality

An existing value and prospective new value are compared using C<values_cmp>
in Glib-Perl 1.220 or a fallback otherwise.  For example in
C<Glib::Param::Double> properties anything within "epsilon" (1e-90 by
default) is close enough.  C<values_cmp> lets ParamSpec subclasses control
what they consider equal.

The core C<Glib::Param::Boxed> only compares by pointer value, which is
fairly useless because boxed objects are frequently copied so you probably
don't have an identical pointer.  ConnectProperties tries to improve this
by:

=over

=item *

C<equal> or C<compare> method from the value type when available.  This
covers C<Gtk2::Gdk::Color>, C<Gtk2::Gdk::Region> and C<Gtk2::TreePath>.

=item *

C<Glib::Strv> compared by string contents.

=item *

C<Gtk2::Border> compared by field values.

=item *

C<Gtk2::Gdk::Cursor> compared by C<type>, though bitmap cursors are still
only by pointer.

=item *

C<Glib::Scalar> compared with C<eq>.  This may be of limited help and it's
probably much better to subclass C<Glib::Param::Scalar> and make a
type-specific C<values_cmp>, if/when that's possible.

=back

Potentially C<Glib::Param::Object> pspecs could benefit from using an
C<equal> or C<compare> method on its value type as done for boxed objects.
But usually when setting a C<Glib::Object> it's a particular object which is
desired, not just contents.  If that's not so then as with C<Glib::Scalar>
it may be better as a C<values_cmp> in a ParamSpec subclass to express which
different objects are equal enough, for both C and Perl code.

=head2 Notifies

If you're writing an object or widget don't forget to explicitly C<notify>
when changing a property outside of C<SET_PROPERTY>.  For example,

    sub set_position {
      my ($self, $newval) = @_;
      if ($self->{'position'} != $newval) {
        $self->{'position'} = $newval;
        $self->notify('position');
      }
    }

This sort of thing is required for any object or widget, but failing to do
so in particular means ConnectProperties won't work.  C<SET_PROPERTY> can
call out to a setter function like this to re-use code if desired.  In that
case the extra C<notify> call is harmless and is collapsed to just one
notify at the end of C<SET_PROPERTY>.

=head1 SEE ALSO

L<Glib::Object>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-connectproperties/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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
