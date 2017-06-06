package Game;
use strict;
use warnings;

our $VERSION = 0.1;

use Moose;
use Auth;
use File::Slurp;
use Data::Printer;
use YAML::XS;
use File::Slurp;
use Crypt::Bcrypt::Easy;
use AppData::Mongo;
use MongoDB;
use MongoDB::OID;

my $auth = Auth->new();
my $mongo = AppData::Mongo->new(collection_name => 'app');
my $db = $mongo->client->get_database("jeopardy");

sub listGames {
	my ($self) = @_;
	
	my $games_rs = $db->get_collection("games");
	
	my $games = [$games_rs->find()->all()];
	return $games;
}

sub saveGame {
	my ($self, $game) = @_;
	my $games = $db->get_collection("games");

	return $games->insert_one($game);
}

sub getGame {
	my ($self, $id) = @_;
	
	my $coll = $db->get_collection("games");
	return $coll->find_one({_id => MongoDB::OID->new(value => $id)});
}

sub setColumnCategory {
	my ($self, $game_id, $pos, $label) = @_;

	my $game = $self->getGame($game_id);

	$game->{categories} = $game->{categories} // [map { "Category $_" } (1..6)];
	$game->{categories}->[$pos - 1] = $label;

	$self->saveGame($game);

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