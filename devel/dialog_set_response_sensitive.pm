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


package Glib::Ex::ConnectProperties::Element::set_response_sensitive;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Gtk2;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 12;

# uncomment this to run the ### lines
#use Smart::Comments;

my $pspec = Glib::ParamSpec->boolean ('sensitive',
                                      'sensitive',
                                      '', # blurb
                                      1,  # default
                                      'writable');
my %pspecs;
BEGIN {
  foreach my $info (Glib::Type->list_values ('Gtk2::ResponseType')) {
    $pspecs{$info->{'nick'}} = $pspec;
  }
}

sub find_property {
  my ($self, $pname) = @_;
  return ($pspecs{$pname}
          || ($pname =~ /^-?\d+$/ && $pspec));
}

use constant read_signals => 'hierarchy-changed';

sub get_value {
  die "oops, set-response-sensitive is meant to be write-only";
}
sub set_value {
  my ($self, $value) = @_;
  $self->{'object'}->set_response_sensitive ($self->{'pname'}, $value);
}

1;
__END__


# =head2 Dialog Set Response Sensitive
# 
# The sensitivity of responses on a C<Gtk2::Dialog>, C<Gtk2::InfoBar>, or
# similarl, can be set from ConnectProperties with
# 
#     set-response-sensitive#ok      boolean, write-only
# 
#     Glib::Ex::ConnectProperties->new
#       ([$label1, 'widget-toplevel#widget'],
#        [$dialog, 'set-response-sensitive#123']);
#
