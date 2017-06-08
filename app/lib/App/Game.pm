package App::Game;
use strict;
use warnings;
our $VERSION = 0.1;

use FindBin;
use Cwd qw(abs_path);

use lib abs_path("$FindBin::Bin/../../../lib");
use lib abs_path("$FindBin::Bin/../../../modules/lib/perl5");

use Dancer2 appname => 'jeopardy';
use Dancer2::Plugin::Flash;
use Data::Printer;
use Game;

my $games = Game->new();

prefix '/game';

get '/join/game_id?' => sub {
    my $count = session("counter");
    session "counter" => ++$count;

	template 'game/join', {
		count => $count
	};
};

get '/run/:game_id?' => sub {
	my $game_id = route_parameters->get('game_id') ;
	my $game;

	if ($game_id) {
		$game = $games->get($game_id);
	}

	if ($game) {
		$games->save($game->{_id}, {'x' => 'y'});

		return template 'game/run', {
			game => $game
		};
	}

	my $all_games = $games->list();

	if (! scalar @{$all_games}) {
		$games->add({
			name => "Fun New Game #" . (int(rand() * 10_000)),
			owner => session('username')
		});
	}

	template 'game/index', {
		games => $all_games
	};
};

get '/random' => sub {
	my $game = $games->add({
		name => "Fun New Game #" . (int(rand() * 10_000)),
		owner => session('username')
	});

	redirect '/game/run/' . $game->inserted_id;
};

post '/new' => sub {
	my $params = request->body_parameters;

	if (!$params->{gameName}) {
		flash(error => 'no game name');
	} else {
		$games->add({
			name => $params->{gameName},
			owner => session('username'),
		});
		flash(success => 'game created');
	}

	redirect '/game/run/';
};

get '/delete/:game_id' => sub {
	my $game_id = route_parameters->get('game_id') ;
	my $game;

	if ($game_id) {
		if ($game_id eq 'all') {
			$games->remove();
		} else {
			$games->remove($game_id);
		}
		flash('success' => 'deleted');
	} else {
		flash('error' => 'no game');
	}

	
	redirect '/game/run/';
};

prefix '/api/game';

post '/update/:game_id' => sub {
	my $game = $games->get(route_parameters->get('game_id'));
	
	my $params = request->body_parameters;
	my $action = $params->{action} || q{};

	if ($action eq 'set-q-a') {
		my $row = $params->{row} || 0;
		my $col = $params->{col} || 0;
		my $answer = $params->{answer} || '[ ANSWER ]';
		my $question = $params->{question} || '[ QUESTION ]';
		
		$games->save($game->{_id}, {"answers.$col.points.$row" => {answer => $answer, question => $question, value => $row + 1 * 200}});
		return 1;
	}
	return 0;
};

1;
