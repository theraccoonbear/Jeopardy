package App::Route::WebSocket;
use strict;
use warnings;
our $VERSION = 0.1;

use FindBin;
use Dancer2 appname => 'jeopardy';
use Dancer2::Plugin::Flash;
use AnyEvent;
use AnyEvent::HTTP;
use Data::Printer;
use App::Model::User;
use App::Model::Game;
use App::Model::Activity;

my $users = App::Model::User->new();
my $games = App::Model::Game->new();
my $activities = App::Model::Activity->new();

prefix '/ws';

my @urls = qw<these are urls>;

get q{/} => sub {
    delayed {
        flush;

        # keep track of responses with a condvar
        my $cv = AnyEvent->condvar;

        # decide what happens when all responses arrive
        $cv->cb( delayed { done; } );

        foreach my $url (@urls) {
            $cv->begin;
            http_get $url, delayed {
                my ( $headers, $body ) = @_;
                content $body;
                $cv->end;
            };
        }
    };
};