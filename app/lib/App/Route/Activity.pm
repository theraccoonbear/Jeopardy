package App::Route::Activity;
use strict;
use warnings;
our $VERSION = 0.1;

use FindBin;
use Dancer2 appname => 'jeopardy';
use Dancer2::Plugin::Flash;
use Data::Printer;
use App::Model::Game;
use App::Model::Activity;

my $games = App::Model::Game->new();
my $activities = App::Model::Activity->new();

prefix '/activity';

get '/from/:game_id' => sub {
	my $game_id = route_parameters->get('game_id') ;
	my $game = $games->get($game_id);
	if (!$game) {
		flash(error => 'game not found');
		return redirect '/game/run/';
	}

	if (!request->parameters->{new}) {
		my $existing_activities = $activities->find({
			game_id => $activities->oid($game_id),
			runner => session('user')->{_id}
		});

		if (scalar @{$existing_activities}) {
			return template 'activity/existing',{
				game => $game,
				existing => [map {
					$_->{game} = $games->get($_->{game_id});
					$_
				} @{$existing_activities}]
			};
		}
	}
	my $new_activity = {
		game_id => $activities->oid($game_id),
		runner => session('user')->{_id},
		players => [],
		state => {
			phase => 'start',
			public => 1,
			active_player => undef,
			current_category => undef,
			current_amount => undef,
			claims => [map { [map { undef } (1..5)] } (1..6)]
		}
	};
	say STDERR "NEW:\n";
	#p($new_activity);
	my $result = $activities->add($new_activity);

	return redirect '/activity/run/' . $result->inserted_id;
};

get '/run/:activity_id' => sub {
	my $activity_id = route_parameters->get('activity_id') ;
	my $activity = $activities->get($activity_id);
	if (!$activity) {
		flash(error => 'activity not found');
		return redirect '/game/run/';
	}

	$activity->{game} = $games->get($activity->{game_id});

	return template 'activity/run', {
		activity => $activity
	};
};

1;