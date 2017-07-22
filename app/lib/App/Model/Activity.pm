package App::Model::Activity;
use strict;
use warnings;

our $VERSION = 0.1;

use MooseX::Singleton;

extends 'App::Model';

use Data::Printer;
use App::Model::User;
use App::Model::Game;

has '+model_name' => (default => 'activity');

sub load_related {
	my ($self, $activity) = @_;
	my $game_id = $activity->{game_id};
	
	my $games = App::Model::Game->instance();
	my $users = App::Model::User->instance();

	$activity->{game} = $games->get($game_id);
	$activity->{runner} = $users->get($activity->{runner_id});

	$activity->{player_count} = $activity->{state}->{players} ? scalar @{ $activity->{state}->{players} } : 0;
	
	return $activity;
}

sub set_active_player {
	my ($self, $activity_id, $player) = @_;

	my $data = {
		'state.active_player' => $player
	};

	$self->save($activity_id, $data);

	return;
}

sub set_phase {
	my ($self, $activity_id, $phase, $meta) = @_;

	if (!$meta) { $meta = {}; }

	my $data = {
		'state.phase' => $phase, 
		'state.meta' => $meta
	};


	if ($meta->{user}) {
		$data->{'state.active_player'} = $meta->{user};
	}

	$self->save($activity_id, $data);

	return;
}

sub claim_answer {
	my ($self, $activity_id, $player, $row, $col) = @_;
	
	my $update = {
		'state.claims.' . $row . q{.} . $col => $player->{username}
	};
	return $self->save($activity_id, $update);
}

sub set_score {
	my ($self, $activity_id, $player, $score) = @_;
	my $act = $self->get($activity_id);
	$act->{state}->{players} = [
		map {
			if ($_->{username} eq $player->{username}) {
				$_->{score} = $score;
			}
			$_;
		}
		@{ $act->{state}->{players} }
	];

	return $self->save($activity_id, { 'state.players' => $act->{state}->{players}});
}

sub award_score {
	my ($self, $activity_id, $player, $score) = @_;
	my $act = $self->get($activity_id);
	$act->{state}->{players} = [
		map {
			if ($_->{username} eq $player->{username}) {
				$_->{score} += $score;
			}
			$_;
		}
		@{ $act->{state}->{players} }
	];

	return $self->save($activity_id, { 'state.players' => $act->{state}->{players}});
}

1;