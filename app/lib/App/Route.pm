package App::Route;

use strict;
use warnings;

use FindBin;
use Cwd qw(abs_path);

use Dancer2 appname => 'jeopardy';
use Dancer2::Plugin::Flash;
use Data::Printer;
use App::Model::User;
use App::Auth;
use App::Route::Game;
use App::Route::Activity;
#use App::Route::WebSocket;
our $VERSION = 0.1;


my $users = App::Model::User->new();
my $auth = App::Auth->new();


prefix undef;

hook before => sub {
	var 'username' => session 'username';

	if (!session('username') && request->path_info !~ m{^/login}xsm) {
		flash(error => 'you must login first');
		redirect '/login';
	}

	say STDERR 'Processing request for: ' . request->path_info;
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
		my $user = $users->getByUsername($params->{username});
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
			my $newuser = $auth->create({
				username => $params->{username},
				password => $params->{password}
			});
			say STDERR "$params->{username} not found. created account.";
			flash(success => 'new user created!');
			session 'username' => $params->{username};
			session 'user' => $users->get($newuser->inserted_id);
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

any qr{.*} => sub {
    status 'not_found';

	my $params = {};
	if (request->path_info =~ m{^/(?<model>[a-z]+[a-zA-Z0-9_-]+)(?:/(?<action>[a-z]+[a-zA-Z0-9_-]+)(?:/(?<id>[a-f0-9]{24}))?)?}xsm) {
		#say STDERR "Were you trying to: " . $+{action} . ' to the ' . $+{id} . ' of ' . $+{model};
		$params->{model} = $+{model};
		$params->{action} = $+{action};
		$params->{id} = $+{id};
	}

    template 'err/404', $params;
};

1;
