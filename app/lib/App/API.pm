package App::API;

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
use Digest::SHA qw(sha256_hex);

use AppData::Mongo;

my $mongo = new AppData::Mongo(collection_name => 'api');

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


my $sab;
if (defined $credentials->{'sabnzbd'}) {
	$sab = new Medac::Downloader::Sabnzbd($credentials->{'sabnzbd'});
} else {
	die "No SABNZBd available.  Bailing out.";
}


post '/download' => sub {
	my $url = body_parameters->get('url');
	my $title = body_parameters->get('title');
	my $user = body_parameters->get('username') || 'mystery_user';
	my $type = body_parameters->get('type') || 'movie';
	
	print STDERR "* download requested by \"$user\": $title ($type)\n";
	
	my $sha = sha256_hex($url);
	my $sha_key = $user . ':' . $sha;
	my $resp = $sab->queueDownload($url, $sha_key, 'cproxy');
	p($resp);

	$mongo->insert({
		title => $title,
		url => $url,
		type => $type,
		hash => $sha,
		status => 'queued',
		user => $user
	});
	
	set 'layout' => 'json';
	template 'json', {
		data => {
			success => 1
		}
	};
	
};

true;
