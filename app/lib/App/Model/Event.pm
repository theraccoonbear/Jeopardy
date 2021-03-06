package App::Model::Event;
use strict;
use warnings;

our $VERSION = 0.1;

use MooseX::Singleton;

extends 'App::Model';

use Data::Printer;
use App::Model::User;
use App::Model::Game;
use App::Model::Activity;

has '+model_name' => (default => 'event');

my $users = App::Model::User->instance();
my $games = App::Model::Game->instance();
my $activities = App::Model::Activity->instance();

# @todo get tailable cursors working
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
	$data->{activity} = $activities->get($activity_id);
	my $event = {
		user_id => $self->oid($user_id),
		activity_id => $self->oid($activity_id),
		action => $action,
		data => $data,
		timestamp => time
	};

	# @todo: use this https://metacpan.org/pod/Hash::Sanitize

	return $self->add($event);
}


1;