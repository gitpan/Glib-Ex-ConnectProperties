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


# set selected-path   select_path()
# model -- its treeview model or undef



package Glib::Ex::ConnectProperties::Element::tree_selection;
use 5.008;
use strict;
use warnings;
use Glib;
use Gtk2;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 17;

# uncomment this to run the ### lines
#use Smart::Comments;


my %pspecs = do {
  my $bool = Glib::ParamSpec->boolean ('e',  # name
                                       '',   # nick
                                       '',   # blurb
                                       1,    # default, unused
                                       'readable');
  ('empty'      => $bool,
   'not-empty'  => $bool,
   'count'      => Glib::ParamSpec->int ('count', # name
                                         '',      # nick
                                         '',      # blurb
                                         0,       # min
                                         32767,   # max
                                         0,       # default, unused
                                         'readable'),

   'selected-path' => Glib::ParamSpec->boxed ('selected-path',  # name
                                              '',               # nick
                                              '',               # blurb
                                              'Gtk2::TreePath',
                                              Glib::G_PARAM_READWRITE),
  )
};
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

use constant read_signals => 'changed';

sub get_value {
  my ($self) = @_;
  ### tree_selection get_value(): "$self->{'object'}"

  my $sel = $self->{'object'};
  my $pname = $self->{'pname'};
  if ($pname eq 'selected-path') {
    return ($sel->get_selected_rows)[0];
  } else {
    my $count = $sel->count_selected_rows;
    if ($pname eq 'empty') {
      return $count == 0;
    } elsif ($pname eq 'not-empty') {
      return $count != 0;
    } else {
      return $count;
    }
  }
}

sub set_value {
  my ($self, $value) = @_;
  ### tree_selection set_value(): "$self->{'object'}"
  ### value: $value && "$value"

  # pname eq "selected-path"
  my $sel = $self->{'object'};
  if (defined $value) {
    ### select_path: $value->to_string
    $sel->select_path ($value);
  } else {
    ### unselect_all
    $sel->unselect_all;
  }
}

1;
__END__


# No compare method for Gtk2::TreeIter.
# Might subclass Glib::Param::Boxed to add one.
# But even then the path is probably easier
#
# 'selected-iter' => Glib::ParamSpec->boxed ('selected-iter',  # name
#                                            '',               # nick
#                                            '',               # blurb
#                                            'Gtk2::TreeIter',
#                                            Glib::G_PARAM_READWRITE),
#                'selected-iter' => sub { scalar($_[0]->get_selected) },
#                'selected-iter' => 'select_iter',
#    tree-selection#selected-iter   Gtk2::TreeIter or undef
