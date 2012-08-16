# Copyright 2012 Kevin Ryde

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


package Glib::Ex::ConnectProperties::Element::textbuffer;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 18;

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

   # dummy name and dummy range, just want an "int" type
   'char-count' => Glib::ParamSpec->int ('char-count',  # name, unused
                                         'char-count',  # nick, unused
                                         '',      # blurb, unused
                                         0,       # min, unused
                                         2**31-1, # max, unused
                                         0,       # default, unused
                                         'readable')  # read-only
  )
};
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

# "notify::text" doesn't seem to be emitted, as of gtk circa 2.24.8
use constant read_signals => 'changed';

sub get_value {
  my ($self) = @_;
  my $textbuf = $self->{'object'};
  my $pname = $self->{'pname'};
  my $char_count = $textbuf->get_char_count;
  if ($pname eq 'empty') {
    return $char_count == 0;
  } elsif ($pname eq 'not-empty') {
    return $char_count != 0;
  } else {
    return $char_count;
  }
}

sub set_value {
  die "oops, textbuffer#char-count is meant to be read-only";
}

1;
__END__
