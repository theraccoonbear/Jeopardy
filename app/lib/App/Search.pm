package App::Search;

use FindBin;
use Cwd qw(abs_path);

use lib abs_path("$FindBin::Bin/../../../lib");
use lib abs_path("$FindBin::Bin/../../../modules/lib/perl5");


use Dancer2;
use File::Slurp;
use Data::Printer;
use Data::Dumper;
use YAML::XS;
use File::Slurp;
use Crypt::Bcrypt::Easy;


use Medac::Search::NZB::Unified;
use Medac::Search::NZB::OMGWTFNZBS;
use Medac::Search::NZB::NZBPlanet;
use AppData::Mongo;

my $mongo = new AppData::Mongo(collection_name => 'search');


sub loadYAML {
	my ($file) = @_;
	
	my $raw_yaml = read_file($file);
	my $yaml = Load($raw_yaml);

	return $yaml;
}

my $access_file = "$FindBin::Bin/../../config/access.yml";
my $access = loadYAML($access_file);

my $credentials_file = "$FindBin::Bin/../../config/credentials.yml";
my $credentials = loadYAML($credentials_file);

my $searcher = new Medac::Search::NZB::Unified();

if (defined $credentials->{'omgwtfnzbs.me'}) {
	my $omg = new Medac::Search::NZB::OMGWTFNZBS($credentials->{'omgwtfnzbs.me'});
	$searcher->addAgent($omg);
}

if (defined $credentials->{'nzbplanet.net'}) {
	my $nzbplanet = new Medac::Search::NZB::NZBPlanet($credentials->{'nzbplanet.net'});
	$searcher->addAgent($nzbplanet);
}


get '/' => sub {
	template 'search/index', {
		Fizz => 'Buzz'
	};
};

get '/movies' => sub {
	template 'search/results', {
		type => 'Movies'
	};
};

get '/movies/:term' => sub {
	my $term = route_parameters->get('term');
	my $idx = 0;
	my $movies = [ sort { $a->{sizebytes} <=> $b->{sizebytes} } map { $_->{'@idx'} = $idx++; $_; } @{ $searcher->searchMovies({terms => $term})}];
	
	template 'search/results', {
		term => $term,
		type => 'Movies',
		results => $movies,
		searched => 1
	};
};

get '/tv' => sub {
	template 'search/results', {
		type => 'TV'
	};
};

get '/tv/:term' => sub {
	my $term = route_parameters->get('term');
	my $idx = 0;
	my $shows = [ sort { $b->{usenetage} <=> $a->{usenetage} } map { $_->{'@idx'} = $idx++; $_; } @{ $searcher->searchTV({terms => $term})}];
	
	template 'search/results', {
		term => $term,
		type => 'TV',
		results => $shows,
		searched => 1
	};
};

true;
