#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../modules/lib/perl5";

our $VERSION = 0.1;

use App::Route;
use Plack::App::WebSocket;
use Plack::Builder;
use JSON::XS;

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
					my ($conn, $msg) = @_;
					my $dat = decode_json($msg);
					$dat->{msg} .= ' PING!';
					$conn->send(encode_json($dat));
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