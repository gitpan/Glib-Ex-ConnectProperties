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

package Glib::Ex::ConnectProperties::Element::object;
use 5.008;
use strict;
use warnings;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 13;

# uncomment this to run the ### lines
#use Smart::Comments;


sub get_value {
  my ($self) = @_;
  return $self->{'object'}->get_property ($self->{'pname'});
}
sub set_value {
  my ($self, $value) = @_;
  $self->{'object'}->set_property ($self->{'pname'}, $value);
}

sub find_property {
  my ($self) = @_;
  return $self->{'object'}->find_property ($self->{'pname'});
}

sub read_signals {
  my ($self) = @_;
  return 'notify::' . $self->{'pname'};
}

1;
__END__
