#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../modules/lib/perl5";

our $VERSION = 0.1;

use App::Route;
use Data::Printer;
use Plack::App::WebSocket;
use Plack::Builder;
use App::Model::Event;
use JSON::XS;
use AnyEvent;

my $events = App::Model::Event->new();

builder {
	mount "/websocket" => Plack::App::WebSocket->new(
		on_error => sub {
			my $env = shift;
			return [500,
					["Content-Type" => "text/plain"],
					["Error: " . $env->{"plack.app.websocket.error"}]];
		},
		on_establish => sub {
			my $conn = shift; ## Plack::App::WebSocket::Connection object
			my $env = shift;  ## PSGI env

			$conn->on(
				message => sub {
					my ($connection, $msg) = @_;
					my $dat = decode_json($msg);
					p($dat);
					if ($dat->{action}) {
						if ($dat->{action} eq 'reveal') {
							$dat = {
								msg => ("Revealing: " . $dat->{catIdx} . ":" . $dat->{rowIdx})
							};
						} elsif ($dat->{action} eq 'subscribe') {
							say STDERR "Subscribing to " . $dat->{activity_id};
							my $cursor = $events->tailFind({
								activity_id => $dat->{activity_id}
							});
							p($cursor);


							$dat->{msg} = 'subscribed';
							$connection->send(encode_json($dat));

							my $seconds = 0.1;
							my $done = AnyEvent->condvar;
							my $w = AnyEvent->timer(after => 0, interval => $seconds, cb => sub {
								if (defined(my $doc = $cursor->next)) {
									say STDERR "NEW EVENT:";
									p($doc);
									$connection->send(encode_json({
										msg => "We got it!",
										data => $doc
									}));
								} else {
									print STDERR 'z';
								}
							});
							$done->recv;
						}
					} else {
						$dat->{msg} .= ' PING!';
					}
					$connection->send(encode_json($dat));
					return 1;
				},
				finish => sub {
					undef $conn;
					warn "Bye!!\n";
				},
			);
		}
	)->to_app;
	mount q{/} => App::Route->to_app;
};