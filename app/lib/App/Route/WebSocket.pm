package App::Route::WebSocket;
use strict;
use warnings;
our $VERSION = 0.1;

use FindBin;
use Dancer2 appname => 'jeopardy';
use Plack::App::WebSocket;
use Dancer2::Plugin::Flash;
use AnyEvent;
use AnyEvent::HTTP;
use Data::Printer;
# use App::Model::User;
# use App::Model::Game;
# use App::Model::Activity;

my $events = App::Model::Event->new();
my $conn;

sub to_app {
    return Plack::App::WebSocket->new(
        on_error => sub {
            my $env = shift;
            return [500,
                    ["Content-Type" => "text/plain"],
                    ["Error: " . $env->{"plack.app.websocket.error"}]];
        },
        on_establish => sub {
            $conn = shift; ## Plack::App::WebSocket::Connection object
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
                            say STDERR "CURSOR:";
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
                    say STDERR "Here we are";
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
}

1;