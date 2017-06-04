package App;

use FindBin;
use Cwd qw(abs_path);

use lib abs_path("$FindBin::Bin/../../lib");
use lib abs_path("$FindBin::Bin/../../modules/lib/perl5");

#use lib abs_path("$FindBin::Bin/../../special/medac/medac/lib");

use Dancer2;
use File::Slurp;
use Data::Printer;
use Data::Dumper;
use YAML::XS;
use File::Slurp;
use Crypt::Bcrypt::Easy;
use Medac::Downloader::Sabnzbd;
use Medac::Search::NZB::Unified;
use Medac::Search::NZB::OMGWTFNZBS;
use Medac::Search::NZB::NZBPlanet;
use AppData::Mongo;

my $mongo = new AppData::Mongo(collection_name => 'app');


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
	print STDERR "Registering search provider: OMGWTFNZBs.me\n";
	my $omg = new Medac::Search::NZB::OMGWTFNZBS($credentials->{'omgwtfnzbs.me'});
	$searcher->addAgent($omg);
}

if (defined $credentials->{'nzbplanet.net'}) {
	print STDERR "Registering search provider: NZBPlanet.net\n";
	my $nzbplanet = new Medac::Search::NZB::NZBPlanet($credentials->{'nzbplanet.net'});
	$searcher->addAgent($nzbplanet);
}

my $sab;
if (defined $credentials->{'sabnzbd'}) {
	print STDERR "Registering download provider: SABNZBd (${\$credentials->{sabnzbd}->{hostname}}:${\$credentials->{sabnzbd}->{port}})\n";
	$sab = new Medac::Downloader::Sabnzbd($credentials->{'sabnzbd'});
} else {
	die "No SABNZBd available.  Bailing out.";
}

get '/' => sub {
	template 'index', {
		Fizz => 'Buzz'
	};
};

get '/search-movies' => sub {
	template 'search', {};
};

get '/search-movies/:term' => sub {
	my $term = route_parameters->get('term');
	my $idx = 0;
	my $movies = [ map { $_->{'@idx'} = $idx++; $_; } @{ $searcher->searchMovies({terms => $term})}];
	
	template 'search', {
		term => $term,
		type => 'movies',
		results => $movies,
		searched => 1
	};
};

post '/api/download' => sub {
	my $url = body_parameters->get('url');
	my $title = body_parameters->get('title');
	
	$sab->queueDownload($url, $title, 'cproxy');
	
	set 'layout' => 'json';
	template 'json', {
		data => {
			success => 1
		}
	};
	
};

1;
