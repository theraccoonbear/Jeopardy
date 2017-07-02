package App::Model::Activity;
use strict;
use warnings;

our $VERSION = 0.1;

use Moo;

extends 'App::Model';

use Data::Printer;
use App::Model::User;
use App::Model::Game;

has '+model_name' => (default => 'activity');

my $users = App::Model::User->new();
my $games = App::Model::Game->new();


sub load_related {
	my ($self, $user) = @_;

	$user->{game} = $games->get($user->{game_id});
	$user->{player_count} = $user->{state}->{players} ? scalar @{$user->{state}->{players}} : 0;
	$user->{runner} = $users->get($user->{runner_id});
	return $user;
}

sub set_phase {
	my ($self, $activity_id, $phase, $meta) = @_;

	if (!$meta) { $meta = {}; }


	$self->save($activity_id, {
		'state.phase' => $phase, 
		'state.meta' => $meta
	});
}

1;