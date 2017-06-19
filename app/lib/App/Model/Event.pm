package App::Model::Event;
use strict;
use warnings;

our $VERSION = 0.1;

use Moo;

extends 'App::Model';

use Data::Printer;
use App::Model::User;
use App::Model::Game;
use App::Model::Activity;

has '+model_name' => (default => 'event');

my $users = App::Model::User->new();
my $games = App::Model::Game->new();
my $activities = App::Model::Activity->new();

sub tailFind {
	my ($self, $activity_id) = @_;

	say STDERR "Getting tailed...";
	# {activity_id => $self->oid($activity_id)}
	my $tailed = $self->collection()->find->tailable(1);
	say STDERR "...OK";
	return $tailed;
}

sub emitEvent {
	my ($self, $activity_id, $type, $data) = @_;

	my $event = {
		activity_id => $activity_id,
		type => $type,
		data => $data
	};

	return $self->add($event);
}


1;