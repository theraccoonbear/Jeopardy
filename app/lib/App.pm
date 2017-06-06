package App;

use strict;
use warnings;

use FindBin;
use Cwd qw(abs_path);

use lib abs_path("$FindBin::Bin/../../lib");
use lib abs_path("$FindBin::Bin/../../modules/lib/perl5");

use Dancer2;
use Dancer2::Plugin::Auth::Tiny;
use File::Slurp;
use Data::Printer;
use Data::Dumper;
use YAML::XS;
use File::Slurp;
use Crypt::Bcrypt::Easy;
use Auth;
use AppData::Mongo;

our $VERSION = 0.1;

my $auth = Auth->new();

my $mongo = AppData::Mongo->new(collection_name => 'app');


sub loadYAML {
	my ($file) = @_;
	
	my $raw_yaml = read_file($file);
	my $yaml = Load($raw_yaml);

	return $yaml;
}

get q{/} => sub {
	template 'index';
};

get '/login' => sub {
	if (session 'username') {
		say STDERR "already logged in as " . session 'username';
		redirect q{/};
	}
	template 'login';
};

post '/login' => sub {
	my $params = request->body_parameters;

	if ($params->{username} && $params->{password}) {
		my $user = $auth->getUser($params->{username});
		if ($user) {
			if ($auth->validateCredentials($params->{username}, $params->{password})) {
				say STDERR "$params->{username} authenticated";
				session 'username' => $params->{username};
				session 'user' => $user;
				var 'username' => $params->{username};
				redirect q{/};
			}
			say STDERR "$params->{username} failed authentication";
		} else {
			my $user = $auth->addUser({
				username => $params->{username},
				password => $params->{password}
			});
			say STDERR "$params->{username} not found. created account.";
			session 'username' => $params->{username};
			session 'user' => $user;
			var 'username' => $params->{username};
			redirect q{/};
		}
	}

	template 'login', {

	};
};

get '/logout' => sub {
	session 'username' => undef;
	var 'username' => undef;
	redirect '/login';
};

1;
