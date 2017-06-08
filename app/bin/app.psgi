#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../modules/lib/perl5";

our $VERSION = 0.1;

#use Dancer2;
use App;
use App::API;
use App::Game;
use Plack::Builder;

builder {
	mount q{/} => App->to_app;
	#mount '/api' => App::API->to_app;
	#mount '/game' => App::Game->to_app;
};