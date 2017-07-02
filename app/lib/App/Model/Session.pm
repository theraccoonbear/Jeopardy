package App::Model::Session;
use strict;
use warnings;

our $VERSION = 0.1;

use Moo;

extends 'App::Model';

use Data::Printer;

has '+model_name' => (default => 'dancer_sessions');

sub get {
	my ($self, $cond) = @_;
	
	my $c = { _id => $cond };
	my $coll = $self->collection();
	return $coll->find_one($c);
	return;
}

1;