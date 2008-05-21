# Copyright 2008 Kevin Ryde

# This file is part of Gtk2-Ex-ConnectProperties.
#
# Gtk2-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ConnectProperties is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More tests => 6;

use Glib::Ex::ConnectProperties;
use POSIX;

SKIP: {
  if (DBL_MANT_DIG - FLT_MANT_DIG < 10) {
    skip 'due to "double" and "float" the same size', 6;
  }

  my $shift = FLT_MANT_DIG + 5;

  {
    my $pspec = Glib::ParamSpec->float ('foo','foo','blurb',
                                        0,100,0,['readable']);
    my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
    is (ref($subr), 'CODE');

    ok ($subr->(2 ** $shift, 2 ** $shift));
    ok ($subr->(2 ** $shift, 2 ** $shift + 1));
  }

  {
    my $pspec = Glib::ParamSpec->double ('foo','foo','blurb',
                                         0,100,0,['readable']);
    my $subr = Glib::Ex::ConnectProperties::_pspec_equality_func ($pspec);
    is (ref($subr), 'CODE');

    ok ($subr->(2 ** $shift, 2 ** $shift));
    ok (! $subr->(2 ** $shift, 2 ** $shift + 1));
  }
}

exit 0;
