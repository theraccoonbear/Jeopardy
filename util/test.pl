#!/usr/bin/env perl
use lib '/opt/src/modules/lib/perl5';
use lib '/opt/src/app/lib';
use AppData::Mongo;
use Data::Printer;

#my $host = $ENV{DBHOST};
#
#my $client     = MongoDB->connect('mongodb://' . $host);
#my $collection = $client->ns('foo.bar'); # database foo, collection bar
#my $result     = $collection->insert_one({ some => 'data' });
#my $data       = $collection->find_one({ _id => $result->inserted_id });
#
#p($data);

my $mongo = new AppData::Mongo();

my $inserted = $mongo->insert({
	some => "things",
	multiple => [
		"one","two","three"
	]
});

p($inserted);