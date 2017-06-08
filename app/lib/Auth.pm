package Auth;
use strict;
use warnings;

our $VERSION = 0.1;

use Moose;
use File::Slurp;
use Data::Printer;
use YAML::XS;
use File::Slurp;
use Crypt::Bcrypt::Easy;
use AppData::DB;

my $mongo = AppData::DB->instance();
my $db = $mongo->get_database("jeopardy");

sub list {
	my ($self) = @_;
	my $users = $db->get_collection("users");
	my $people = [$users->find()->all()];
	return $people;
}

sub add {
	my ($self, $user) = @_;
	$user->{password} = bcrypt->crypt($user->{password});

	my $users = $db->get_collection("users");

	return $users->insert_one($user);
}

sub validateCredentials {
	my ($self, $username, $password) = @_;

	my $user = $self->get($username);
	if (!$user) {
		say STDERR "User not found: $username";
		return;
	}
	return bcrypt->compare(text => $password, crypt => $user->{password});
}

sub get {
	my ($self, $username) = @_;
	
	my $users = $db->get_collection("users");
	my $user = [$users->find({username => $username})->all()];

	return $user ? $user->[0] : undef;
}

1;