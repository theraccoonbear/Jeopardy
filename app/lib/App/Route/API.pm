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

use AppData::DB;

my $mongo = AppData::DB->instance();

post '/download' => sub {
	my $url = body_parameters->get('url');
	my $title = body_parameters->get('title');
	my $user = body_parameters->get('username') || 'mystery_user';
	my $type = body_parameters->get('type') || 'movie';
	
	set 'layout' => 'json';
	template 'json', {
		data => {
			success => 1
		}
	};
	
};

1;
