package AppData::Mongo;

use lib '../../../modules/lib/perl5';

use Moose;
use MongoDB;

my $host = $ENV{DBHOST} || '127.0.0.1';

has 'client' => (
	is => 'rw',
	isa => 'MongoDB::MongoClient',
	default => sub {
		my $url = 'mongodb://' . $host;
		print STDERR "MongoDB: $host\n";
		my $client = MongoDB->connect($url);
		return $client;
	}
);

has 'collection_name' => (
	is => 'rw',
	isa => 'Str'
);

has 'collection' => (
	is => 'rw',
	isa => 'Maybe[MongoDB::Collection]'
);

sub BUILD {
	my $self = shift @_;
	$self->setCollection('cproxy.' . $self->collection_name);
}

#my $result     = $collection->insert_one({ some => 'data' });
#my $data       = $collection->find_one({ _id => $result->inserted_id });

sub setCollection {
	my ($self, $collection) = @_;
	$self->collection($self->client->ns($collection));
}

sub insert {
	my ($self, $data) = @_;
	my $ret = $self->collection->insert_one($data);
	return $ret;
}

sub getAll {
	my ($self, $collection, $conditions) = @_;
	my $found = $self->collection->find();
	return $found;
}

1;