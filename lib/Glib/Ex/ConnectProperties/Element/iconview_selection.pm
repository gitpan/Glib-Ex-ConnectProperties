# Copyright 2011 Kevin Ryde

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



package Glib::Ex::ConnectProperties::Element::iconview_selection;
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

use constant read_signals => 'selection-changed';

sub get_value {
  my ($self) = @_;
  ### iconview_selection get_value()

  my @paths = $self->{'object'}->get_selected_items;
  my $pname = $self->{'pname'};
  if ($pname eq 'empty') {
    return scalar(@paths) == 0;
  } elsif ($pname eq 'not-empty') {
    return scalar(@paths) != 0;
  } elsif ($pname eq 'count') {
    return scalar(@paths);
  } else {
    return $paths[0];
  }
}

sub set_value {
  my ($self, $value) = @_;
  ### iconview_selection set_value(): $value && "$value"

  # pname eq "selected-path"
  my $iconview = $self->{'object'};
  if (defined $value) {
    ### select_path: $value->to_string
    $iconview->select_path ($value);
  } else {
    ### unselect_all
    $iconview->unselect_all;
  }
}

#------------------------------------------------------------------------------
# unused

# sub _iconview_count_selected_items {
#   my ($iconview) = @_;
#   my @paths = $iconview->get_selected_items;
#   return scalar(@paths);
# }


1;
__END__
