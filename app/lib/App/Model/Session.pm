package App::Model::Session;
use strict;
use warnings;

our $VERSION = 0.1;

use Moo;

extends 'App::Model';

use Data::Printer;

has '+model_name' => (default => 'dancer_sessions');

1;