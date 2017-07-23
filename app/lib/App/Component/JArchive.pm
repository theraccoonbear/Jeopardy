package App::Component::JArchive;
use strict;
use warnings;

our $VERSION = 0.1;

use Moo;
use Dancer2 appname => 'jeopardy';
use Data::Printer;
use Web::Scraper;
use WWW::Mechanize;

has 'mech' => (
	'is' => 'rw',
	'default' => sub {
		my $ua_string = "Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4";
		# my $cookie_jar = HTTP::Cookies->new();
		# $cookie_jar->clear();
		my $www_mech = WWW::Mechanize->new(
			autocheck => 0,
			#cookie_jar => $cookie_jar,
			#SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
			PERL_LWP_SSL_VERIFY_HOSTNAME => 0,
			verify_hostname => 0,
			ssl_opts => {
				verify_hostname => 0
			}
		);
		$www_mech->agent($ua_string);
		return $www_mech;
	}
);

has 'base_url' => (
	is => 'rw',
	default => 'http://j-archive.com'
);

my $index_scraper = scraper {
	process '#content tr', 'seasons[]' => scraper {
		process '//td[1]/a', 'season' => sub {
			my ($v) =  @_;
			my $season = {
				#raw => $v
			};
			if ($v->as_trimmed_text =~ /Season\s+(?<num>\d+)/xsm) {
				$season->{number} = $+{num};
				$season->{url} = $v->attr('href');
			}
			return $season;
		};
	};
};

my $season_scraper = scraper {
	process '#content tr', 'episodes[]' => scraper {
		process '//td[1]/a', 'episode' => sub {
			my ($v) =  @_;
			my $episode = {
				#raw => $v
			};
			p($v);
			if ($v->as_trimmed_text =~ /#\s+(?<episode_number>\d+.+?aired\s+(?<air_date>(?<year>\d{4})-(?<mon>\d{2})-(?<dom>\d{2})))/xsm) {
				$episode->{number} = $+{episode_number};
				$episode->{air_date} = $+{air_date};
				$episode->{url} = $v->attr('href');
			}
			return $episode;
		};
	};
};

my $game_scraper = scraper {
	process '#jeopardy_round', 'jeopardy_round' => scraper {
		process 'table.round .category_name', 'category[]' => 'TEXT';
		foreach my $idx (1..5) {
			process 'table.round > tr:nth-child(' . ($idx + 1) . ') .clue_text', 'answer_' . ($idx * 200) . '[]' => 'TEXT';
			process 'table.round > tr:nth-child(' . ($idx + 1) . ') div[onmouseover]', 'question_' . ($idx * 200) . '[]' => sub {
				my $omo = $_->attr('onmouseover');
				if ($omo =~ m/correct_response">(?<resp>.+?)<\/em/gismx) {
					return $+{resp};
				}
				return $omo;
			};
		}
	};
};

sub getGame {
	my ($self, $id) = @_;
	my $url = my $season_url = $self->base_url . '/showgame.php?game_id=' . $id;
	my $game = {};

	say STDERR "Getting $url";

	$self->mech->get($url);
	if ($self->mech->success) {
		my $content = $self->mech->content;
		my $results = $game_scraper->scrape($content);
		
		$game->{results} = $results;
	}

	p($game);

	return $game;
}

sub listSeasons {
	my ($self) = @_;

	my $results = session 'j-archive_seasons';
	if (!$results) {
		my $season_url = $self->base_url . '/listseasons.php';

		$self->mech->get($season_url);
		if (!$self->mech->success) {
			p($self->mech);
			die "Can't load $season_url: $!";
		}

		my $content = $self->mech->content;
		$results = $index_scraper->scrape($content);
		$results = [map { $_->{season} } @{$results->{seasons}}];
	}

	$results = [ 
		sort { $a->{number} <=> $b->{number} }
		@{$results}
	];
	session 'j-archive_seasons', $results;
	return $results;
}

sub getSeason {
	my ($self, $season_num) = @_;
	my $results = session "j-archive_season-$season_num";
	my $season_index = $self->listSeasons();
	if (!$results) {
		my $season_url = $self->base_url . '/showseason.php?season=' . $season_num;

		$self->mech->get($season_url);
		if (!$self->mech->success) {
			p($self->mech);
			die "Can't load $season_url: $!";
		}

		my $content = $self->mech->content;
		$results = $season_scraper->scrape($content);
		$results = [map { $_->{episode} } @{$results->{episodes}}];
	}

	$results = [ 
		sort { $a->{number} <=> $b->{number} }
		grep { defined $_->{number} }
		@{$results}
	];
	p($results);
	#session 'j-archive_seasons', $results;
	return {
		episodes => $results
	};
}

1;