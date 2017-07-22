package App::Model;
use strict;
use warnings;

our $VERSION = 0.1;
use Carp;
use MooseX::Singleton;
use Data::Printer;
use App::DB;

use MongoDB::OID;
use Cwd qw(abs_path);

my $mongo = App::DB->instance();
my $db = $mongo->get_database("jeopardy");

has 'model_name' => (
	is => 'rw',
	isa => 'Str',
	default => '_model_'
);

sub oid {
	my ($self, $oid) = @_;
	return MongoDB::OID->new($oid);
}

sub collection {
	my ($self) = @_;
	# say STDERR "Getting collection: " . $self->model_name;
	# say STDERR "__PACKAGE__: " . __PACKAGE__;
	return $db->get_collection($self->model_name);
}

sub _cond {
	my ($self, $cond) = @_;
	if (!$cond) {
		$cond = {};
	} elsif (!ref $cond) {
		$cond = {_id => $self->oid($cond)};
	} elsif (ref $cond eq 'MongoDB::OID') {
		$cond = {_id => $cond};
	}

	return $cond;
}

sub prepareIDs {
	my ($self, $results) = @_;

	if (ref $results ne 'ARRAY') {
		$results = [$results];
	}

	foreach my $res (@$results) {
		$res->{id} = $res->{_id}->to_string;
	}

	return $results;
}

sub list {
	my ($self) = @_;
	
	my $coll = $self->collection();
	
	my $res = [$coll->find()->all()];
	return $res;
}

sub find {
	my ($self, $cond) = @_;
	
	my $coll = $self->collection();
	
	my $objects = [$coll->find($self->_cond($cond))->all()];
	return $objects;
}

sub add {
	my ($self, $obj) = @_;
	my $coll = $self->collection();
	#$obj->{_created}
	return $coll->insert_one($obj);
}

sub save {
	my ($self, $cond, $obj) = @_;

	my $coll = $self->collection();
	return $coll->update_one($self->_cond($cond), {'$set' => $obj});
}


sub get {
	my ($self, $cond, $extra) = @_;

	my $c = $self->_cond($cond);
	# say STDERR $self->model_name . "->get() Condition:";
	# p($c);
	my $coll = $self->collection();
	my $doc = $coll->find_one($c);
	if ($extra && $extra->{load_related}) {
		$doc = $self->load_related($doc);
	}
	return $doc;
}

sub remove {
	my ($self, $cond) = @_;

	my $coll = $self->collection();
	return $coll->delete_many($self->_cond($cond));
}


1;
