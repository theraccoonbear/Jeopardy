package App::Route::Game;
use strict;
use warnings;
our $VERSION = 0.1;

use FindBin;
use Dancer2 appname => 'jeopardy';
use Dancer2::Plugin::Flash;
use Data::Printer;
use App::Model::Game;
use App::Data;

my $games = App::Model::Game->new();
my $data = App::Data->new();

prefix '/game';

get '/join/game_id?' => sub {
	template 'game/join', {
	};
};

get '/' => sub {
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

get '/edit/:game_id?' => sub {
	my $game_id = route_parameters->get('game_id') ;
	my $game;

	if ($game_id) {
		$game = $games->get($game_id);
	}

	if (!$game) {
		return redirect '/game/';
	}

	var 'game' => $game;
	return template 'game/run', {
		game => $game
	};
};

get '/random' => sub {
	my $game = $games->add({
		name => "Fun New Game #" . (int(rand() * 10_000)),
		owner => session('username')
	});

	redirect '/game/edit/' . $game->inserted_id;
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

	redirect '/game/';
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

	
	redirect '/game/';
};

get '/import' => sub {
	my $files = $data->listJSON();

	return template 'game/import', {
		files => $files
	};
};

post '/import' => sub {
	my $params = request->body_parameters;
	my $file = $params->{file} || '';

	say STDERR "FILE: $file";

	my $files = $data->listJSON();
	if (scalar grep { /$file/xsm } @{$files}) {
		my $loaded_data = $data->loadJSON($file);
		$loaded_data->{owner} = session('username');
		my $game = $games->add($loaded_data);
		redirect '/game/edit/' . $game->inserted_id;
	}

	return template 'game/import', {
		files => $files
	};
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
		
		$games->save($game->{_id}, {"answers.$row.points.$col" => {answer => $answer, question => $question, value => ($row + 1) * 200}});
		return 1;
	}
	return 0;
};

1;