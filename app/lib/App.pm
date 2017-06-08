package App;

use strict;
use warnings;

use FindBin;
use Cwd qw(abs_path);

use lib abs_path("$FindBin::Bin/../../lib");
use lib abs_path("$FindBin::Bin/../../modules/lib/perl5");

use Dancer2 appname => 'jeopardy';
use Dancer2::Plugin::Flash;
use Data::Printer;
use Auth;
our $VERSION = 0.1;

my $auth = Auth->new();

prefix undef;

hook before => sub {
	var 'username' => session 'username';

	if (!session('username') && request->path_info !~ m{^/login}xsm) {
		flash(error => 'you must login first');
		redirect '/login';
	}
};

get q{/} => sub {
	return template 'index';
};

get '/login' => sub {
	if (session 'username') {
		say STDERR "already logged in as " . session 'username';
		redirect q{/};
	}
	return template 'login';
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
			flash(error => 'invalid login');
			say STDERR "$params->{username} failed authentication";
		} else {
			my $newuser = $auth->addUser({
				username => $params->{username},
				password => $params->{password}
			});
			say STDERR "$params->{username} not found. created account.";
			flash(success => 'new user created!');
			session 'username' => $params->{username};
			session 'user' => $newuser;
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
