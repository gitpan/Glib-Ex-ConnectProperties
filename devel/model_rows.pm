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

package Glib::Ex::ConnectProperties::Element::model_rows;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Glib;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 10;

# uncomment this to run the ### lines
#use Smart::Comments;


# model-rows:empty
# model-rows:non-empty
# model-rows:count
# model-rows:top-count

# my $conn = Glib::Ex::ConnectProperties->new
#   ([$model,  'model-rows:empty' ],
#    [$button, 'sensitive']);


my %pspecs = do {
  # dummy name as paramspec name cannot be empty
  my $pspec = Glib::ParamSpec->boolean ('m',
                                        'm',
                                        '',       # blurb
                                        0,        # default
                                        ['readable']);
  ('empty'     => $pspec,
   'non-empty' => $pspec)
};
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'empty'} = ! $self->{'object'}->get_iter_first;
  return $self;
}

sub read_signal {
  my ($self) = @_;
  return ($self->{'empty'} ? 'row-inserted' : 'row-deleted');
}

sub signal_handler {
  my ($self) = @_;
  my $model = $self->{'object'};
  my $signame;
  if ($self->{'empty'}) {
    # row-inserted, now not empty
    $self->{'empty'} = 0;
    $signame = 'row-deleted';
  } else {
    # non-empty, row-deleted
    if ($self->{'object'}->get_iter_first) {
      return; # still non-empty
    }
    $self->{'empty'} = 1;
    $signame = 'row-inserted';
  }
  my $ids = $self->{'ids'};
  $ids->disconnect;
  $ids->add ($model->signal_connect
             ('row-inserted',
              \&Glib::Ex::ConnectProperties::_do_read_handler,
              $self));

  shift->SUPER::signal_handler(@_);
}

sub get_value {
  my ($self) = @_;
  return ($self->{'empty'} ^ ($self->{'pname'} eq 'non-empty'));
}
sub set_value {
  die "oops, model-rows is meant to be read-only";
}

1;
__END__
