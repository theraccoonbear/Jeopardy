package App::Component::JArchive;
use strict;
use warnings;

our $VERSION = 0.1;

use Moo;
use Dancer2 appname => 'jeopardy';
use Data::Printer;
use Web::Scraper;
use WWW::Mechanize;
#use JSON::XS;
use DateTime;

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

my $round_scraper = scraper {
	process 'table.round .category_name', 'categories[]' => 'TEXT';
	foreach my $idx (1..5) {
		process 'table.round > tr', 'scores[]' => scraper {
			process 'td.clue', 'clues[]' => scraper {
				process '.clue_text', 'answer' => 'TEXT';
				process '.clue_header td:nth-child(2)', 'value' => sub {
					my $v = $_->as_trimmed_text();
					$v =~ s/[^\d]+//gsmx;
					return 1 * $v;
				};

				process '.clue_header td:nth-child(2)', 'daily_double' => sub {
					my $v = $_->as_trimmed_text();
					return $v =~ m/DD:/xsm ? 1 : 0;
				};

				process 'div[onmouseover]', 'question' => sub {
					my $omo = $_->attr('onmouseover');
					if ($omo =~ m/correct_response">(?<resp>.+?)<\/em/gismx) {
						return $+{resp};
					}
					return $omo;
				};
			};
		};
		
		# process 'table.round > tr:nth-child(' . ($idx + 1) . ') .clue_text', 'answer_' . ($idx * 200) . '[]' => 'TEXT';
		# process 'table.round > tr:nth-child(' . ($idx + 1) . ') .clue_header td:nth-child(2)', 'value_' . ($idx * 200) . '[]' => sub {
		# 	my $v = $_->as_trimmed_text();
		# 	$v =~ s/[^\d]+//gsmx;
		# 	return 1 * $v;
		# };
		# process 'table.round > tr:nth-child(' . ($idx + 1) . ') .clue_header td:nth-child(2)', 'daily_double_' . ($idx * 200) . '[]' => sub {
		# 	my $v = $_->as_trimmed_text();
		# 	return $v =~ m/DD:/xsm ? 1 : 0;
		# };
		# process 'table.round > tr:nth-child(' . ($idx + 1) . ') div[onmouseover]', 'question_' . ($idx * 200) . '[]' => sub {
		# 	my $omo = $_->attr('onmouseover');
		# 	if ($omo =~ m/correct_response">(?<resp>.+?)<\/em/gismx) {
		# 		return $+{resp};
		# 	}
		# 	return $omo;
		# };
	}
};

my $game_scraper = scraper {
	process '#game_title h1', 'name' => 'TEXT';
	process '#jeopardy_round', 'jeopardy_round' => $round_scraper;
	process '#double_jeopardy_round', 'double_jeopardy_round' => $round_scraper;
};

sub processRound {
	my ($self, $scraped) = @_;

	my $round = {};
	$round->{categories} = [
		map {
			{ name => $_ }
		} @{ $scraped->{categories} }
	];
	$round->{answers} = [];

	foreach my $val_idx (1..5) {
		my $round_values = [
			grep { 
				defined $_ 
			} 
			map { 
				$_->{value}
			} @{ $scraped->{scores}->[$val_idx]->{clues} }];
		
		say STDERR "ROUND VALUES:";
		p($round_values);
			
			#$scraped->{'value_' . ($val_idx * 200)};
		my $count = {};
		foreach (@$round_values) {
			$count->{$_}++;
		}
		
		my $value = (sort { $count->{$b} <=> $count->{$a} } keys %$count)[0];



		push @{ $round->{answers} }, {
			points => [ map {
				{ 
					# answer => $scraped->{'answer_' . ($val_idx * 200)}[$_],
					# question => $scraped->{'question_' . ($val_idx * 200)}[$_],
					# daily_double => ($scraped->{'daily_double_' . ($val_idx * 200)}[$_] ? 1 : 0),
					# value => $value
					answer => $scraped->{scores}->[$val_idx]->{clues}->[$_]->{answer},
					question => $scraped->{scores}->[$val_idx]->{clues}->[$_]->{question},
					daily_double => $scraped->{scores}->[$val_idx]->{clues}->[$_]->{daily_double} ? 1 : 0,
					value => defined $scraped->{scores}->[$val_idx]->{clues}->[$_]->{answer} ? $value : ''
				}
			} (0..5)]
		};
	}
	return $round;
}

sub getFullGame {
	my ($self, $id) = @_;
	my $url = my $season_url = $self->base_url . '/showgame.php?game_id=' . $id;
	my $game = {};

	say STDERR "Getting $url";

	$self->mech->get($url);
	if ($self->mech->success) {
		my $content = $self->mech->content;
		my $results = $game_scraper->scrape($content);
		say STDERR ":::RESULTS:::";
		p($results);
		say STDERR ":::/RESULTS:::";
		my $round_1 = $self->processRound($results->{jeopardy_round});
		$round_1->{name} = $results->{name} . ' (Round 1)';
		$round_1->{jarchive_id} = $id;
		$round_1->{round} = 'jeopardy';
		$round_1->{fetched} = DateTime->now();

		my $round_2 = $self->processRound($results->{double_jeopardy_round}, 400);
		$round_2->{name} = $results->{name} . ' (Round 2)';
		$round_2->{jarchive_id} = $id;
		$round_2->{round} = 'double_jeopardy';
		$round_2->{fetched} = DateTime->now();

		$game->{jeopardy} = $round_1;
		$game->{double_jeopardy} = $round_2;
	}

	say STDERR ":::GAME:::";
	p($game);
	say STDERR ":::/GAME:::";

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