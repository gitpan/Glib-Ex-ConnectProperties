# Copyright 2007, 2008 Kevin Ryde

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


use strict;
use warnings;
use Gtk2 '-init';
use Scalar::Util;

{
  Gtk2::HBox->new;
  foreach my $type ('Glib::Float',
                    'Gtk2::HBox',
                    'Gtk2::Gdk::EventMask',
                    'Gtk2::Gdk::CursorType',
                    'Glib::Flags',
                    'Glib::Enum',
                    'Gtk2::PackType') {
    print "$type ancestors: ";
    eval { print join (' ', Glib::Type->list_ancestors ($type)),"\n"; }
      or print "error $@";
  }
  exit 0;
}
{
  my $type = 'Gtk2::Gdk::Rectangle';
  print $type->can('equal') ? "yes\n" : "no\n";
  my $rect = Gtk2::Gdk::Rectangle->new (1,2,3,4);
  print "$rect\n";
  exit 0;
}
{
  my $y = 123;
  my $x = \$y;
  print UNIVERSAL::isa($x,'foo') ? "yes\n" : "no\n";
  print $x->isa('foo') ? "yes\n" : "no\n";
  exit 0;
}
{
  my $type = 'Glib::String';
#   $type = 'Gtk2::Gdk::Color';
#   $type = 'Gtk2::Gdk::EventMask';
#   $type = 'Foo';
  print $type->isa($type) ? "yes\n" : "no\n";
  exit 0;
}
{
  my $type = 'Gtk2::Gdk::Color';
  $type = 'Gtk2::Gdk::EventMask';
  print $type->can('equal') ? "yes\n" : "no\n";
}
{
  my $type = 'Gtk2::Widget';
  my $supertype = 'Gtk2::Object';
  print $type->isa($supertype) ? "yes\n" : "no\n";
}

my $label = Gtk2::Label->new ('Hello');
my $button = Gtk2::CheckButton->new_with_label ('Press');

require Glib::Ex::ConnectProperties;
my $conn = Glib::Ex::ConnectProperties->new ([$label,'sensitive'],
                                             [$button,'active']);

print "\nfrozen:\n";
$label->freeze_notify;
$button->set (active => 1);
$button->set (active => 0);

print "\nthaw:\n";
$label->thaw_notify;

exit 0;
