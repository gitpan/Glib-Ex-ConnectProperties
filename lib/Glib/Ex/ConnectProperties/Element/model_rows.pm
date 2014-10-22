# model-rows#empty
# model-nullity#empty
# model-content#empty
# model-contents#empty
# model-emptiness#empty
# model-emptiness#not-empty




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

our $VERSION = 14;

# uncomment this to run the ### lines
#use Smart::Comments;

my %pspecs = do {
  # dummy name as paramspec name cannot be empty
  my $pspec = Glib::ParamSpec->boolean ('model-rows',
                                        'model-rows',
                                        '',       # blurb
                                        0,        # default, unused
                                        'readable');
  ('empty'     => $pspec,
   'not-empty' => $pspec)
};
sub find_property {
  my ($self) = @_;
  return $pspecs{$self->{'pname'}};
}

sub connect_signals {
  my ($self) = @_;
  ### model_rows connect_signals()
  my $model = $self->{'object'};

  # row-deleted permanent
  $self->{'ids'} = Glib::Ex::SignalIds->new
    ($model,
     $model->signal_connect ('row-deleted', \&_do_deleted, $self));

  # row-inserted while not empty
  unless ($model->get_iter_first) {
    $self->{'ids2'} = Glib::Ex::SignalIds->new
      ($model,
       $model->signal_connect ('row-inserted', \&_do_inserted, $self));
  }
}
# row-deleted signal handler
sub _do_deleted {
  my $self = $_[-1];
  ### model_rows _do_deleted()
  my $model = $self->{'object'};
  if (! $self->{'object'}->get_iter_first) {
    ### has become empty
    $self->{'ids2'} = Glib::Ex::SignalIds->new
      ($model,
       $model->signal_connect ('row-inserted', \&_do_inserted, $self));
    Glib::Ex::ConnectProperties::_do_read_handler($self);
  }
}
# row-inserted signal handler, connected only while model is empty
sub _do_inserted {
  my $self = $_[-1];
  ### model_rows _do_inserted()
  ### has become not-empty
  delete $self->{'ids2'};
  Glib::Ex::ConnectProperties::_do_read_handler($self);
}


sub get_value {
  my ($self) = @_;
  ### model_rows get_value()
  ### is: (defined($self->{'object'}->get_iter_first) ^ ($self->{'pname'} eq 'not-empty')) 

  return (defined($self->{'object'}->get_iter_first)
          ^ ($self->{'pname'} eq 'empty'));
}
sub set_value {
  die "oops, model-rows is meant to be read-only";
}

1;
__END__




#     model-rows#top-count        integer, read-only


# sub connect {
#   my ($self) = @_;
#   my $h = $self->{'href'} = ($model->{__PACKAGE__} ||= do {
#     my $empty = ! $self->{'object'}->get_iter_first;
#     my $href = { empty => $empty,
#                  elems => [ $self ]};
#     $href->{'signal_ids'} = Glib::Ex::SignalIds->new
#       ($model,
#        $object->signal_connect ($empty ? 'row-inserted' : 'row-deleted',
#                                 \&_do_signal,
#                                 $href))
#     });
#   Scalar::Util::weaken ($h->{'elems'}->[@$h] = $self);
# }
# sub _do_signal {
#   my $href = $_[-1];
#   my $signame;
#   if ($href->{'empty'}) {
#     $href->{'empty'} = 0;
#     $signame = 'row-deleted';
#   } else {
#     if ($self->{'object'}->get_iter_first) {
#       return; # still not empty
#     }
#     $self->{'empty'} = 1;
#     $signame = 'row-inserted';
#   }
# 
#   my $ids = $self->{'signal_ids'};
#   $ids->disconnect;
#   $ids->add ($model->signal_connect ($signame, \&_do_signal, $href));
# 
#   my $elems = $href->{'elems'};
#   for (my $i = 0; $i < @$elems; ) {
#     if (my $elem = $elems->[$i]) {
#       $elem->signal_handler;
#       $i++
#     } else {
#       splice @$elems, $i,1;
#     }
#   }
# }
# sub DESTROY {
#   my ($self) = @_;
#   if (! @{$self->{'href'}->{'elems'}}) {
#     delete $self->{'href'}->{'signal_ids'};
#   }
# }

# model-rows#empty
# model-rows#not-empty
# model-rows#count
# model-rows#top-count

# my $conn = Glib::Ex::ConnectProperties->new
#   ([$model,  'model-rows#empty' ],
#    [$button, 'sensitive']);















# sub read_signals {
#   return ($self->{'empty'} ? 'row-inserted' : 'row-deleted');
# }
# 
# sub signal_handler {
#   my ($self) = @_;
#   my $model = $self->{'object'};
#   my $signame;
#   if ($self->{'empty'}) {
#     # row-inserted signal, now not empty
#     $self->{'empty'} = 0;
#     $signame = 'row-deleted';
#   } else {
#     # not-empty, row-deleted signal
#     if ($self->{'object'}->get_iter_first) {
#       return; # still not-empty
#     }
#     $self->{'empty'} = 1;
#     $signame = 'row-inserted';
#   }
#   my $ids = $self->{'ids'};
#   $ids->disconnect;
#   $ids->add ($model->signal_connect
#              ('row-inserted',
#               \&Glib::Ex::ConnectProperties::_do_read_handler,
#               $self));
# 
#   shift->SUPER::signal_handler(@_);
# }


#   $self->{'ids2'} = Glib::Ex::SignalIds->new ($model);
#   if (! $self->{'empty'}) {
#     $self->{'ids2'}->add
#       ($model->signal_connect ('row-inserted', \&_do_inserted, $self));
#   }
# 
#     _reconnect($self,'row-inserted',\&_do_inserted);
# sub _reconnect {
#   my ($self, $signame, $handler) = @_;
#   my $model = ;
#   my $ids = $self->{'ids'};
#   $ids->disconnect;
#   $ids->add ($self->{'object'}->signal_connect
#              ('row-inserted', $handler, $self));
# }


