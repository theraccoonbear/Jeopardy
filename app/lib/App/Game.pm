package App::Game;
use strict;
use warnings;
our $VERSION = 0.1;

use FindBin;
use Cwd qw(abs_path);

use lib abs_path("$FindBin::Bin/../../../lib");
use lib abs_path("$FindBin::Bin/../../../modules/lib/perl5");

use Dancer2;
use Dancer2::Plugin::Auth::Tiny;
use File::Slurp;
use Data::Printer;
use Data::Dumper;
use YAML::XS;
use File::Slurp;
use Crypt::Bcrypt::Easy;
use Game;

my $games = Game->new();

get '/join/game_id?' => needs login => sub {
    my $count = session("counter");
    session "counter" => ++$count;

	template 'game/join', {
		count => $count
	};
};

get '/run/:game_id?' => needs login => sub {
	my $game_id = route_parameters->get('game_id') ;
	my $game;

	if ($game_id) {
		$game = $games->getGame($game_id);
	}

	if ($game) {
		return template 'game/run', {
			game => $game
		};
	}

	my $all_games = $games->listGames();

	if (! scalar @{$all_games}) {
		$games->saveGame({
			name => "Fun New Game #" . (int(rand() * 10_000))
		});
	}

	template 'game/index', {
		games => $all_games
	};
};

post '/create' => needs login => sub {
	my $params = request->body_parameters;

	if ($params->{name}) {
		$games->saveGame({
			name => $params->{name},
			owner => session('username'),
		})
	}

};

1;
