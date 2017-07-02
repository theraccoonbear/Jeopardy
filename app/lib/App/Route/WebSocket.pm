package App::Route::WebSocket;
use strict;
use warnings;
our $VERSION = 0.1;
use utf8;

use Dancer2 appname => 'jeopardy';
use Plack::App::WebSocket;
use AnyEvent;
use AnyEvent::HTTP;
use Data::Printer;
use JSON::XS;
use List::Util qw(min max);
use App::Model::Session;

my $events = App::Model::Event->new();
my $sessions = App::Model::Session->new();
my $json = JSON::XS->new->ascii->pretty->allow_nonref->allow_blessed;

sub to_app {
    return Plack::App::WebSocket->new(
        on_error => sub {
            my $env = shift;

            say STDERR "WebSocket error: " . $env->{"plack.app.websocket.error"};
            return [500,
                    ["Content-Type" => "text/plain"],
                    ["Error: " . $env->{"plack.app.websocket.error"}]];
        },
        on_establish => sub {
            my $conn = shift; ## Plack::App::WebSocket::Connection object
            my $env = shift;  ## PSGI env
            my $w;
            my $cookies = {map { split(/=/, $_) } split(/;\s*/, $env->{HTTP_COOKIE} || '')};
            my $session;
            #my $cursor;

            say STDERR "Cookies:";
            p($cookies);

            say STDERR "WebSocket connecting...";
            if ($cookies->{'dancer.session'}) {
                say STDERR "Getting session...";
                $session = $sessions->get($cookies->{'dancer.session'});
                say STDERR "Session:";
                p($session);
            }
            # if (!$session) {
            #     $conn->close();
            # }
            say STDERR "WebSocket established";

            $conn->on(
                message => sub {
                    my ($connection, $msg) = @_;
                    my $dat = decode_json($msg);
                    say STDERR "WebSocket message:";
                    #p($msg);
                    p($dat);

                    my $resp = {};
                    
                    if ($dat->{action}) {
                        if ($dat->{action} eq 'reveal') {
                            $events->emitEvent($session->{data}->{user}->{_id}->value, $dat->{activity_id}, 'reveal', {
                                row => $dat->{payload}->{row},
                                col => $dat->{payload}->{col},
                            });
                        } elsif ($dat->{action} eq 'subscribe') {
                            say STDERR "Subscribing to " . $dat->{activity_id};
                            $resp->{msg} = 'subscribed';
                            my $seconds = 0.1;
                            my $last_event = time;
                            $w = AnyEvent->timer(after => 0, interval => $seconds, cb => sub {
                                my $new_events = $events->find({timestamp => { '$gt' => $last_event }});

                                if (scalar @{$new_events} > 0) {
                                    my $cnt = scalar @$new_events;
                                    say STDERR "$cnt events";
                                    $connection->send($json->encode({
                                        payload => $new_events,
                                        now => time
                                    }));
                                    my $old_last = $last_event;
                                    foreach my $ev (@{$new_events}) {
                                        $last_event = max($last_event, $ev->{timestamp});
                                    }
                                } else {
                                    #print STDERR '.';
                                }
                            });
                        } elsif ($dat->{action} eq 'buzz') {
                            $events->emitEvent($session->{data}->{user}->{_id}->value, $dat->{activity_id}, 'buzz', {user_id => $session->{data}->{user}->{_id}->value});
                        } else {
                            say STDERR "Unknown WebSocket Action: " .  $dat->{action};
                        }
                    }
                    if ($resp->{msg}) {
                        $resp->{now} = time;
                        $connection->send($json->encode($resp));
                    }
                    return;
                },
                finish => sub {
                    undef $conn;
                    #warn "Bye!!\n";
                    say STDERR "WebSocket finish occured";
                },
            );
            return $conn;
        }
    )->to_app;
}

1;