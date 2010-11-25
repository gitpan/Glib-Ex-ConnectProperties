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

package Glib::Ex::ConnectProperties::Element;
use 5.008;
use strict;
use warnings;

use Carp;
our @CARP_NOT = ('Glib::Ex::ConnectProperties');

our $VERSION = 12;

# uncomment this to run the ### lines
#use Smart::Comments;


sub new {
  my $class = shift;
  return bless { @_ }, $class;
}

sub check_property {
  my ($self) = @_;
  ### Element check_property()
  $self->find_property
    || croak ("ConnectProperties: ", $self->{'object'},
              " has no property '", $self->{'pname'}, "'");
}

sub is_readable {
  my ($self) = @_;
  ### Element is_readable()
  my $pspec;
  return (! ($pspec = $self->find_property)
          || ($pspec->get_flags & 'readable'));
}
sub is_writable {
  my ($self) = @_;
  ### Element is_writable()
  my $pspec;
  return (! ($pspec = $self->find_property)
          || ($pspec->get_flags & 'writable'));
}

1;
__END__

# sub value_validate {
#   my ($self, $value) = @_;
#   if (my $pspec = $self->find_property) {
#     # value_validate() is wrapped in Glib 1.220, remove the check when ready
#     # to demand that version
#     if (my $coderef = $pspec->can('value_validate')) {
#       (undef, $value) = $pspec->$coderef($value);
#     }
#   }
#   return $value;
# }
#
# sub value_equal {
#   my ($self, $v1, $v2) = @_;
#   if (my $pspec = $self->find_property) {
#     return _pspec_equal ($pspec, $v1, $v2);
#   }
#   return $v1 eq $v2;
# }

