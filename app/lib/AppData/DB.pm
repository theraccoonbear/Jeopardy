package AppData::DB;
use strict;
use warnings;
use lib '../../../modules/lib/perl5';
use MongoDB;

our $VERSION = 0.1;

my $host = $ENV{DBHOST} || '127.0.0.1';
my $port = $ENV{DBPORT} || 27017;

my $url = "mongodb://$host:$port";
say STDERR "Connecting to $url";
my $client = MongoDB->connect($url);
say STDERR "connected!";
my $count = 0;

sub instance {
	$count++;
	say STDERR "$count MongoDB handle retrievals";
	return $client;
}

1;