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


# Finding out what different property types are used.


use strict;
use warnings;
use Data::Dumper;
use List::Util;
use Scalar::Util;
use Glib;
use Gtk2 '-init';
use Gtk2::Pango;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->show;

my $bitmap = Gtk2::Gdk::Bitmap->create_from_data (undef, "\0", 1, 1);

{
  my $entry = Gtk2::Entry->new;
  $entry->set('inner-border', { left => 0 });
  my $border = $entry->get('inner-border');
  print "Gtk2::Border ", Dumper ($border);

  my $pspec = $entry->find_property ('editable');
  print "boolean ", Dumper ($pspec);
}

{
  my $about = Gtk2::AboutDialog->new;
  my $a = $about->get ('artists');
  print "Strv ", Dumper ($a);
  $about->set_artists ('Picasso', 'Matisse');
  my $a = $about->get ('artists');
  print "Strv ", Dumper ($a);
}

my @packages;
foreach (keys %::) {
  walk ($_, '');
}
sub walk {
  my ($name, $level) = @_;
  if ($name eq 'main::') { return; }

  my $classname = $name;
  $classname =~ s/::$//g or return;
  push @packages, $classname;

  no strict;
  if (defined %{$name}) {
    foreach my $part (keys %{$name}) {
      walk ($name.$part, $level.' ');
    }
  }
}
# print join("\n",@packages);

my %base_types = ('Glib::Boolean' => 1,
                  'Glib::Float' => 1,
                  'Glib::Object' => 1);
my %covered;
my %other;
foreach my $class (@packages) {
  if ($class =~ /::_LazyLoader$/) { next; }
  eval { $class->find_property ('x'); };
  if (! $class->can('list_properties')) { next; }

  my @props;
  eval { @props = $class->list_properties; } or next;
  foreach my $pspec (@props) {
    my $type = $pspec->get_value_type;

    if ($type->isa ('Glib::Enum')) {
      $covered{'Glib::Enum'}{$type} = 1;
      next;
    }
    if ($pspec->isa ('Glib::Param::Enum')) {
      $covered{'enum'}{$type} = 1;
      next;
    }
    if ($pspec->isa ('Glib::Param::Flags')) {
      $covered{'flags'}{$type} = 1;
      next;
    }
          
    if ($pspec->isa ('Glib::Param::String')) {
      next;
    }


    if ($type->isa('Glib::Object')
       || $pspec->isa ('Glib::Param::Object')) {
      $covered{'GObject'}{$type} = 1;
      next;
    }
    if ($type->can('equal')) {
      $covered{'equal'}{$type} = 1;
      next;
    }
    if ($type->can('eq')) {
      $covered{'eq'}{$type} = 1;
      next;
    }
    if ($type->can('compare')) {
      $covered{'compare'}{$type} = 1;
      next;
    }

    if ($base_types{$type}) {
      next;
    }
    if (List::Util::first {$type->isa($_)} keys %base_types) {
      next;
    }

    if ($type eq 'Glib::String'
        || $type eq 'Glib::Double'
        || $type eq 'Glib::Int'
        || $type eq 'Glib::UInt') {
      next;
    }

    push @{$other{$type}}, $class;
  }
}

print Dumper (\%covered);
print Dumper (\%other);

exit 0;
