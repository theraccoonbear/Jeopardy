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
use App::Component::JArchive;

my $games = App::Model::Game->instance();
my $activities = App::Model::Activity->instance();
my $data = App::Data->new();
my $jarchive = App::Component::JArchive->new();

prefix '/game';

hook before => sub {
	var 'extra_scripts' => ['game.js']
};

get '/join/game_id?' => sub {
	template 'game/join', {
	};
};

get q{/} => sub {
	my $all_games = $games->list();

	$all_games = [
		map {
			$games->load_related($_)
		} @{ $all_games }
	];

	if (! scalar @{$all_games}) {
		$games->add({
			name => "Fun New Game #" . (int(rand() * 10_000)),
			owner => session('username')
		});
		$all_games = $games->list();
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
	var 'extra_scripts' => ['game.js'];

	#p($game);
	#say STDERR json_encode($game);
	return template 'game/edit', {
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
			$game = $games->get($game_id, {load_related => 1});
			if ($game->{ActivityCount}) {
				say STDERR "Removing activities: " . $game->{ActivityCount};
				$activities->remove({game_id => $activities->oid($game_id)});
			}
			$games->remove($game_id);
		}
		flash('success' => 'deleted');
	} else {
		flash('error' => 'no game');
	}

	
	redirect '/game/';
};

get '/export/:game_id' => sub {
	my $game_id = route_parameters->get('game_id') ;
	my $game;

	if ($game_id) {
		$game = $games->get($game_id);
	}

	if (!$game) {
		flash('error' => 'no game found');
		return redirect '/game/';
	}

	var 'game' => $game;
	return template 'game/export', {
		game => $game
	};
};

get '/import' => sub {
	my $files = $data->listJSON();

	return template 'game/import', {
		files => $files
	};
};

post '/import' => sub {
	my $params = request->body_parameters;
	my $file = $params->{file} || q{};

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

# get '/j-archive/:season_id?' => sub {
# 	my $season_num = route_parameters->get('season_id') ;

# 	if ($season_num) {
# 		my $season = $jarchive->getSeason($season_num);
# 		return template 'game/jarchive-season', {
# 			episodes => $season->{episodes},
# 			season_num => $season_num
# 		};
# 	}

# 	my $seasons = $jarchive->listSeasons();

# 	return template 'game/jarchive-index', {
# 		seasons => $seasons
# 	};
# };



get '/j-archive/:game_id' => sub {
	my $game_id = route_parameters->get('game_id') ;

	if ($game_id) {
		my $ids = [split /-/xsm, $game_id];
		my $base_id = $ids->[0];
		my $span = scalar @{$ids} < 2 ? 0 : ($ids->[1] - $base_id );
		my $last_id;
		say STDERR "Grabbing from $base_id to " . ($base_id + $span);

		foreach my $idx (0..$span) {
			my $fetch_id = $base_id + $idx;
			say STDERR "Fetching j-archive #". $fetch_id;
			my $fullGame = $jarchive->getFullGame($fetch_id);

			$fullGame->{jeopardy}->{owner} = session('username');
			my $new_game = $games->add($fullGame->{jeopardy});
			$last_id = $new_game->inserted_id;
			say STDERR "Stored #" . $fetch_id . " round 1 as " . $last_id;

			$fullGame->{double_jeopardy}->{owner} = session('username');
			$new_game = $games->add($fullGame->{double_jeopardy});
			$last_id = $new_game->inserted_id;
			say STDERR "Stored #" . $fetch_id . " round 2 as " . $last_id;
		}

		redirect '/game/edit/' . $last_id;
	}

	redirect '/game/';
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