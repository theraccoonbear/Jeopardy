package App::Auth;
use strict;
use warnings;

our $VERSION = 0.1;

use Moo;
use Data::Printer;
use App::Model::User;
use Crypt::Bcrypt::Easy;
use App::DB;

my $users = App::Model::User->new();

sub list {
	my ($self) = @_;
	return $users->find();
}

sub create {
	my ($self, $user) = @_;
	$user->{password} = bcrypt->crypt($user->{password});
	return $users->add($user);
}

sub validateCredentials {
	my ($self, $username, $password) = @_;

	my $user = $users->getByUsername($username);
	if (!$user) {
		say STDERR "User not found: $username";
		return;
	}
	return bcrypt->compare(text => $password, crypt => $user->{password});
}

1;