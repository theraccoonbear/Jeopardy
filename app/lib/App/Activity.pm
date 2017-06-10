package App::Activity;
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
use Data;
use Activity;

my $games = Game->new();
my $data = Data->new();
my $activities = Activity->new();

prefix '/activity';

get '/from/:game_id' => sub {
	my $game_id = route_parameters->get('game_id') ;
	my $game = $games->get($game_id);
	if (!$game) {
		flash(error => 'game created');
		redirect '/games/run/'
	}

	my $result = $activities->add({
	});
};

1;