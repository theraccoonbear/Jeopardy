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
	my $cond = {
		activity_id => $self->oid($activity_id)
	};

	my $tailed = $self
		->collection()
		->find($cond)
		->tailable_await(1);
		# ->max_await_time_ms(1000);
	#p($tailed);
	say STDERR "...OK";
	return $tailed;
}

sub emitEvent {
	my ($self, $user_id, $activity_id, $action, $data) = @_;

	$action =~ s/[^A-Za-z_]+/_/xsm;

	my $event = {
		user_id => $self->oid($user_id),
		activity_id => $self->oid($activity_id),
		action => $action,
		data => $data,
		timestamp => time
	};

	return $self->add($event);
}


1;