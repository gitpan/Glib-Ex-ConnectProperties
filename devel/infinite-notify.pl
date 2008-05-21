# Copyright 2008 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


# A set from a notify going back and forwards endlessly.


package Foo;
use strict;
use warnings;
use Glib;
use Glib::Object::Subclass
  Glib::Object::,
  properties => [Glib::ParamSpec->boolean
                 ('myprop',
                  'myprop',
                  'Blurb.',
                  0,
                  Glib::G_PARAM_READWRITE)
                ];

package main;
use strict;
use warnings;

my $f1 = Foo->new;
my $f2 = Foo->new;

$f1->signal_connect (notify => sub {
                       print "f1 notify, set f2\n";
                       sleep 1;
                       $f2->set('myprop',0);
                     });
$f2->signal_connect (notify => sub {
                       print "f2 notify, set f1\n";
                       sleep 1;
                       $f1->set('myprop',0);
                     });

$f1->set('myprop',0);

my $context = Glib::MainContext->default;
my $mainloop = Glib::MainLoop->new ($context);
$mainloop->run;
exit 0;
