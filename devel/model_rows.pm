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

our $VERSION = 11;

# uncomment this to run the ### lines
#use Smart::Comments;


# model-rows#empty
# model-rows#non-empty
# model-rows#count
# model-rows#top-count

# my $conn = Glib::Ex::ConnectProperties->new
#   ([$model,  'model-rows#empty' ],
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

sub read_signals {
  return ($self->{'empty'} ? 'row-inserted' : 'row-deleted');
}

sub connect {
  my ($self) = @_;
  my $h = $self->{'href'} = ($model->{__PACKAGE__} ||= do {
    my $empty = ! $self->{'object'}->get_iter_first;
    my $href = { empty => $empty,
                 elems => [ $self ]};
    $href->{'signal_ids'} = Glib::Ex::SignalIds->new
      ($model,
       $object->signal_connect ($empty ? 'row-inserted' : 'row-deleted',
                                \&_do_signal,
                                $href))
    });
  Scalar::Util::weaken ($h->{'elems'}->[@$h] = $self);
}
sub _do_signal {
  my $href = $_[-1];
  my $signame;
  if ($href->{'empty'}) {
    $href->{'empty'} = 0;
    $signame = 'row-deleted';
  } else {
    if ($self->{'object'}->get_iter_first) {
      return; # still not empty
    }
    $self->{'empty'} = 1;
    $signame = 'row-inserted';
  }

  my $ids = $self->{'signal_ids'};
  $ids->disconnect;
  $ids->add ($model->signal_connect ($signame, \&_do_signal, $href));

  my $elems = $href->{'elems'};
  for (my $i = 0; $i < @$elems; ) {
    if (my $elem = $elems->[$i]) {
      $elem->_signal_handler ($elem);
      $i++
    } else {
      splice @$elems, $i,1;
    }
  }
}
sub DESTROY {
  my ($self) = @_;
  if (! @{$self->{'href'}->{'elems'}}) {
    delete $self->{'href'}->{'signal_ids'};
  }
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

# =head2 Tree Model Rows
# 
# The existence of rows in a C<Gtk2::TreeModel> can be accessed with
# 
#     treemodel#empty            boolean, read-only
#     treemodel#non-empty        boolean, read-only
#     treemodel#count-rows       integer, read-only
#     treemodel#count-top-rows   integer, read-only
# 
# These are all read-only, so cannot change the model's contents, but might
# for instance be connected up to make a control widget sensitive only when a
# model has some rows.
# 
#     Glib::Ex::ConnectProperties->new
#       ([$model, 'treemodel#non-empty'],
#        [$button, 'sensitive']);
