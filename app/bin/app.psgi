#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../modules/lib/perl5";

use App;
use App::API;
use App::Search;
use Plack::Builder;

builder {
	mount '/'	=> App->to_app;
	mount '/api' => App::API->to_app;
	mount '/search' => App::Search->to_app;
};