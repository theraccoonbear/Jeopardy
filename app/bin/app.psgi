#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../modules/lib/perl5";

our $VERSION = 0.1;

use App::Route;
use App::Route::WebSocket;
use Data::Printer;
use Plack::Builder;

builder {
	mount '/websocket' => App::Route::WebSocket->to_app();
	mount q{/} => App::Route->to_app;
};