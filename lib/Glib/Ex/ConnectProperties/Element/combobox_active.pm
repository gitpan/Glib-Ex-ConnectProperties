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


package Glib::Ex::ConnectProperties::Element::combobox_active;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Gtk2;
use Gtk2::Ex::ComboBoxBits 32; # v.32 for get_active_text()
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 17;

# uncomment this to run the ### lines
#use Smart::Comments;

my %pspecs =
  (exists => Glib::ParamSpec->boolean ('has-active', # name
                                       '',           # nick
                                       '',           # blurb
                                       0,            # default, unused
                                       'readable'),  # read-only
   iter => Glib::ParamSpec->boxed ('iter', # name
                                   '',     # nick
                                   '',     # blurb
                                   'Gtk2::TreeIter', # obj type
                                   Glib::G_PARAM_READWRITE),
   path => Glib::ParamSpec->boxed ('path',  # name
                                   '',      # nick
                                   '',      # blurb
                                   'Gtk2::TreePath', # boxed type
                                   Glib::G_PARAM_READWRITE),
   text => Glib::ParamSpec->string ('text',  # name
                                    '',      # nick
                                    '',      # blurb
                                    '',      # default
                                    Glib::G_PARAM_READWRITE),
  );
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

use constant read_signals => 'changed';

my %get_method = (exists => sub { !! $_[0]->get_active_iter },
                  iter   => 'get_active_iter',
                  path   => \&Gtk2::Ex::ComboBoxBits::get_active_path,
                  text   => 'get_active_text',
                 );
sub get_value {
  my ($self) = @_;
  ### combobox_active get_value()
  my $method = $get_method{$self->{'pname'}};
  return $self->{'object'}->$method;
}

my %set_method = (iter => (eval{Gtk2->VERSION(1.240);1}
                           ? 'set_active_iter'
                           # no $iter==undef until 1.240
                           : sub {
                             my ($combobox, $iter) = @_;
                             if ($iter) {
                               $combobox->set_active_iter($iter);
                             } else {
                               $combobox->set_active(-1);
                             }
                           }),
                  path => \&Gtk2::Ex::ComboBoxBits::set_active_path,
                  text => \&Gtk2::Ex::ComboBoxBits::set_active_text,
                 );
sub set_value {
  my ($self, $value) = @_;
  ### combobox_active set_value()
  my $method = $set_method{$self->{'pname'}};
  return $self->{'object'}->$method ($value);
}

1;
__END__

# 'combobox-active#exists'
# 'combobox-active#iter'
# 'combobox-active#path'
# 'combobox-active#text'


# maybe ...
# 'combobox-active#column-N'



# maybe ...
#
# 'path-string' => Glib::ParamSpec->string ('path-string',
#                                                  '',  # nick
#                                                  '',  # blurb
#                                                  '',  # default, unused
#                                                  Glib::G_PARAM_READWRITE),
#                   'path-string' => \&_combobox_get_active_path_string,
#                   'path-string' => \&_combobox_set_active_path_string,
# sub _combobox_get_active_path_string {
#   my ($combobox) = @_;
#   my $path;
#   return (($path = _combobox_get_active_path($_[0]))
#           && $path->to_string);
# }
# sub _combobox_set_active_path_string {
#   my ($combobox, $str) = @_;
#   Gtk2::Ex::ComboBoxBits::set_active_path
#       ($combobox, Gtk2::TreePath->new_from_string($str));
# }
