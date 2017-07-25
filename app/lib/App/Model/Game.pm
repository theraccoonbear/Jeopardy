package App::Model::Game;
use strict;
use warnings;

our $VERSION = 0.1;

use MooseX::Singleton;

use boolean;

extends 'App::Model';

use Data::Printer;
use App::Model::Activity;

has '+model_name' => (default => 'games');

sub load_related {
	my ($self, $game) = @_;
	my $act = App::Model::Activity->instance();
	$game->{Activities} = $act->find({game_id =>  $self->oid($game->{_id})});
	$game->{ActivityCount} = scalar @{ $game->{Activities} };

	return $game;
}

sub add {
	my ($self, $game) = @_;

	$game->{categories} = $game->{categories} // [map { 
		{
			name => "Jeopardy! Category No. $_"
		}
		
	} (1..6)];

	# @todo: add support for multiple daily double
	my $dd_row = int(rand(5)) + 1;
	my $dd_col = int(rand(6)) + 1;

	say STDERR "Daily double @ $dd_row, $dd_col";

	$game->{answers} = $game->{answers} // [map {
		my $outer_cnt = $_;
		{points => [map {
			my $inner_cnt = $_;
			my $value = $outer_cnt * 200;
			{
				value => $value,
				answer => "\$$value Answer for Category $_.",
				question => "\$$value Question for Category $_?",
				daily_double => (($dd_row == $outer_cnt && $dd_col == $inner_cnt) ? true : false)
			}
		} (1..6)]};
	} (1..5)];

	my $coll = $self->collection();

	return $coll->insert_one($game);
}


sub setColumnCategory {
	my ($self, $game_id, $pos, $label) = @_;

	my $game = $self->get($game_id);

	$game->{categories}->[$pos - 1] = $label;

	$self->save($game_id, $game);

	return $game;
}

sub joinGame {
	my ($self, $username, $game_id) = @_;

	my $user = $self->getUser($username);
	if (!$user) {
		say STDERR "User not found: $username";
		return;
	}
	return;
}

1;