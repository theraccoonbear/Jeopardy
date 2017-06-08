#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../modules/lib/perl5";

our $VERSION = 0.1;

#use Dancer2;
use App;
use Plack::Builder;

builder {
	mount q{/} => App->to_app;
};