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


package Glib::Ex::ConnectProperties::Element::tree_selection;
use 5.008;
use strict;
use warnings;
use Glib;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 13;

# uncomment this to run the ### lines
#use Smart::Comments;


my %pspecs = do {
  my $bool = Glib::ParamSpec->int ('e',  # name
                                   'e',  # nick
                                   '',   # blurb
                                   1,    # default, unused
                                   'readable');
  (empty        => $bool,
   'not-empty'  => $bool,
   count => Glib::ParamSpec->int ('count', # name
                                  'count', # nick
                                  '',      # blurb
                                  0,       # min
                                  32767,   # max
                                  0,       # default, unused
                                  'readable');

   'selected-path' => Glib::ParamSpec->boxed ('selected-path',  # name
                                              'selected-path',  # nick
                                              '',               # blurb
                                              'Gtk2::TreePath',
                                              'readable');

   'selected-iter' => Glib::ParamSpec->boxed ('selected-iter',  # name
                                              'selected-iter',  # nick
                                              '',               # blurb
                                              'Gtk2::TreePath',
                                              'readable');
  )
};
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

use constant read_signals => 'changed';

my %get_method = (empty       => sub {  ! $_[0]->count_selected_rows },
                  'not-empty' => sub { !! $_[0]->count_selected_rows },
                  count           => 'count_selected_rows',
                  'selected-path' => sub { ($_[0]->get_selected_rows)[0] },
                  'selected-iter' => 'get_selected', # in scalar context
                 );
sub get_value {
  my ($self) = @_;
  ### tree_selection get_value()
  my $method = $get_method{$self->{'pname'}};
  return $sel->$method;
}

sub set_value {
  die "ConnectProperties: oops, tree-selection is meant to be read-only";
}

1;
__END__


=head2 Tree Selection

Rows selected in a C<Gtk2::TreeSelection> object (as used by
C<Gtk2::TreeView>) can be accessed with

    tree-selection#empty           boolean, read-only
    tree-selection#not-empty       boolean, read-only
    tree-selection#count           integer, read-only
    tree-selection#selected-path   Gtk2::TreePath or undef, read-only
    tree-selection#selected-iter   Gtk2::TreeIter or undef, read-only

They're all read-only update with the C<changed> signal from the selection
object.  For example the "not-empty" might be connected up to make a delete
button sensitive only when at least one row is selected,

    Glib::Ex::ConnectProperties->new
      ([$treeselection, 'model-rows#not-empty'],
       [$button,        'sensitive', write_only => 1]);

C<selected-path> and C<selected-iter> are the first selected row.  They're
intended for use with "single" selection mode where there's only zero or one
rows selected.  They're probably of limited use but are included for
completeness.
