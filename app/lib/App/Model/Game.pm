package App::Model::Game;
use strict;
use warnings;

our $VERSION = 0.1;

use Moo;

use boolean;

extends 'App::Model';

#use App::Auth;
use Data::Printer;
#use App::DB;
#use MongoDB::OID;
#use Cwd qw(abs_path);

has '+model_name' => (default => 'games');

# my $auth = App::Auth->new();
# my $mongo = App::DB->instance();
# my $db = $mongo->get_database("jeopardy");

# sub _cond {
# 	my ($self, $cond) = @_;
# 	if (!$cond) {
# 		$cond = {};
# 	} elsif (!ref $cond) {
# 		$cond = {_id => MongoDB::OID->new($cond)};
# 	} elsif (ref $cond eq 'MongoDB::OID') {
# 		$cond = {_id => $cond};
# 	}

# 	return $cond;
# }

# sub list {
# 	my ($self) = @_;
	
# 	my $games_rs = $db->get_collection("games");
	
# 	my $games = [$games_rs->find()->all()];
# 	return $games;
# }

sub load_related {
	my ($self, $game) = @_;

}

sub add {
	my ($self, $game) = @_;

	$game->{categories} = $game->{categories} // [map { 
		{
			name => "Jeopardy! Category No. $_"
		}
		
	} (1..6)];

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

# sub save {
# 	my ($self, $cond, $game) = @_;

# 	my $games = $db->get_collection("games");
# 	return $games->update_one($self->_cond($cond), {'$set' => $game});
# }

# sub get {
# 	my ($self, $cond) = @_;
	
# 	my $coll = $db->get_collection("games");
# 	return $coll->find_one($self->_cond($cond));
# }

# sub remove {
# 	my ($self, $cond) = @_;

# 	my $coll = $db->get_collection("games");
# 	return $coll->delete_many($self->_cond($cond));
# }

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