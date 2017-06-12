package App::Route::Activity;
use strict;
use warnings;
our $VERSION = 0.1;

use FindBin;
use Dancer2 appname => 'jeopardy';
use Dancer2::Plugin::Flash;
use Data::Printer;
use App::Model::User;
use App::Model::Game;
use App::Model::Activity;

my $users = App::Model::User->new();
my $games = App::Model::Game->new();
my $activities = App::Model::Activity->new();

prefix '/activity';
get q{/} => sub {
	my $existing_activities = [map {
		$activities->load_related($_)
	} @{$activities->find()}];


	return template 'activity/index', {
		existing => $existing_activities,
		count => scalar @{$existing_activities}
	};
};

get '/from/:game_id' => sub {
	my $game_id = route_parameters->get('game_id') ;
	my $game = $games->get($game_id);
	if (!$game) {
		flash(error => 'game not found');
		return redirect '/game/run/';
	}

	if (!request->parameters->{new}) {
			my $existing_activities = [map {
				$_->{game} = $games->get($_->{game_id});
				$_
			} @{
				$activities->find({
					game_id => $activities->oid($game_id),
					runner_id => $activities->oid(session('user')->{_id})
				})
			}];

		if (scalar @{$existing_activities}) {
			return template 'activity/existing',{
				game => $game,
				existing => $existing_activities,
				count => scalar @{$existing_activities}
			};
		}
	}

	my $new_activity = {
		game_id => $activities->oid($game_id),
		runner_id => $activities->oid(session('user')->{_id}),
		public => 1,
		state => {
			phase => 'start',
			players => [],
			active_player => undef,
			current_category => undef,
			current_amount => undef,
			claims => [map { [map { undef } (1..5)] } (1..6)]
		}
	};
	my $result = $activities->add($new_activity);

	return redirect '/activity/run/' . $result->inserted_id;
};

get '/run/:activity_id' => sub {
	my $activity_id = route_parameters->get('activity_id') ;
	my $activity = $activities->get($activity_id);
	if (!$activity) {
		flash(error => 'activity not found');
		return redirect '/game/';
	}
	$activity->{game} = $games->get($activity->{game_id});

	var 'activity' => $activity;

	return template 'activity/run', {
		activity => $activity
	};
};

get '/delete/:activity_id' => sub {
	my $activity_id = route_parameters->get('activity_id') ;
	my $activity = $activities->get($activity_id);
	if (!$activity) {
		flash(error => 'activity not found');
		return redirect '/activity/';
	}
	$activities->remove($activity_id);
	flash(success => 'deleted activity');

	return redirect '/activity/';
};

get '/join/:activity_id' => sub {
	my $activity_id = route_parameters->get('activity_id') ;
	my $activity = $activities->get($activity_id);
	if (!$activity) {
		flash(error => 'activity not found');
		return redirect '/activity/';
	}

	my $cnt = scalar grep {
		$_->{username} eq session 'username';
	} @{$activity->{players}};

	say STDERR "COUNT: $cnt";

	if (!$cnt) {
		push @{$activity->{players}}, {
			username => session('username'),
			score => 0
		};
		$activities->save($activity->{_id}, $activity);
	}

	return redirect '/activity/play/' . $activity_id;
};

get '/play/:activity_id' => sub {
	my $activity_id = route_parameters->get('activity_id') ;
	my $activity = $activities->get($activity_id);
	if (!$activity) {
		flash(error => 'activity not found');
		return redirect '/activity/';
	}

	my $cnt = scalar grep {
		$_->{username} eq session 'username';
	} @{$activity->{players}};

	say STDERR "COUNT: $cnt";

	if (!$cnt) {
		return redirect '/activity/join/' . $activity_id;
	}

	$activity = $activities->load_related($activity);

	template 'activity/play', {
		activity => $activity
	};
};

1;