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



# no signal for child added, emission of parent-set on child widget only
# when parent-set to undef must check all for which container decreased

# container#empty
# container#not-empty
# container#count-children
#   emission hook of parent-set probably, as nothing on container itself

# container-children#empty
# container-children#not-empty
# container-children#count



package Glib::Ex::ConnectProperties::Element::container;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Scalar::Util;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 18;

# uncomment this to run the ### lines
#use Smart::Comments;

# my $conn = Glib::Ex::ConnectProperties->new
#   ([$menu,   'container-children#not-empty' ],
#    [$button, 'sensitive']);


my %pspecs = do {
  # dummy name as paramspec name cannot be empty string
  my $pspec = Glib::ParamSpec->boolean ('e', # name
                                        'e', # name
                                        '',  # blurb
                                        0,   # default
                                        'readable');
  ('empty'     => $pspec,
   'not-empty' => $pspec,
   'count'     =>  Glib::ParamSpec->int ('count',  # name
                                         'count',  # nick
                                         '',   # blurb
                                         0,    # min
                                         999,  # max, unused
                                         0,    # default
                                         'readable'),
  )
};
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

my $emission_hook_id;
my $instance_count = 0;

sub new {
  $emission_hook_id ||= Gtk2::Widget->signal_add_emission_hook
    (parent_set => \&_do_parent_set);

  my $self = shift->SUPER::new(@_);
  Scalar::Util::weaken
      ($self->{'object'}->{'Glib_Ex_ConnectProperties_container'}->{$self+0} = $self);
  return $self;
}

sub DESTROY {
  my ($self) = @_;
  if (my $object = $self->{'object'}) {
    my $href = $object->{'Glib_Ex_ConnectProperties_container'};
    delete $href->{$self+0};
    if (! %$href) {
      delete $object->{'Glib_Ex_ConnectProperties_container'};
    }
  }
  if (! --$instance_count) {
    Gtk2::Widget->signal_remove_emission_hook ($emission_hook_id);
    undef $emission_hook_id;
  }
}

use constant read_signals => ();

sub _do_parent_set {
  my ($invocation_hint, $param_list) = @_;
  my ($widget, $old_parent) = @$param_list;

  if ($old_parent) {
    foreach my $self (@{$old_parent->{'Glib_Ex_ConnectProperties_container'}}) {
      if ($self->{'pname'} eq 'count'
          || ($self->{'pname'} ne 'empty'
              && ! $self->{'is_empty'})) {
        Glib::Ex::ConnectProperties::_do_read_handler ($self);
      }
    }
  }
  if (my $parent = $widget->get_parent) {
    foreach my $self (@{$parent->{'Glib_Ex_ConnectProperties_container'}}) {
      if ($self->{'pname'} eq 'count'
          || ($self->{'pname'} eq 'not-empty'
              && $self->{'is_empty'})) {
        $self->{'is_empty'} = 0;
        Glib::Ex::ConnectProperties::_do_read_handler ($self);
      }
    }
  }
}

sub get_value {
  my ($self) = @_;
  my @children = $self->{'object'}->get_children;
  my $pname = $self->{'pname'};
  if ($pname eq 'count') {
    return scalar(@children);
  }
  # "empty" or "not-empty"
  return (@children != 0) ^ ($pname eq 'empty');
}

sub set_value {
  die "oops, container-children is meant to be read-only";
}

1;
__END__
