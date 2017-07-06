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
use boolean;

my $events = App::Model::Event->new();
my $activities = App::Model::Activity->new();
my $sessions = App::Model::Session->new();
my $json = JSON::XS->new->ascii->pretty->allow_nonref->allow_blessed->convert_blessed;

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
            my $cookies = {map { split(/=/xsm) } split(/;\s*/xsm, $env->{HTTP_COOKIE} || '')};
            my $session;
            my $user;
            
            #my $cursor;

            #say STDERR "Cookies:";
            #p($cookies);

            say STDERR "WebSocket connecting...";
            if ($cookies->{'dancer.session'}) {
                say STDERR "Getting session " . $cookies->{'dancer.session'} . "...";
                $session = $sessions->get($cookies->{'dancer.session'});
                $user = $session->{data}->{user};
                #say STDERR "Session:";
                #p($session);
            }

            

            # if (!$session) {
            #     $conn->close();
            # }
            say STDERR "WebSocket established";

            $conn->on(
                message => sub {
                    my ($connection, $msg) = @_;
                    my $dat = decode_json($msg);
                    my $act;

                    my $resp = {};
                    
                    if ($dat->{action}) {
                        say STDERR "WebSocket message: '" . $dat->{action} . "' from '" . $user->{username} . "'";
                        #p($dat);
                        $act = $activities->get($dat->{activity_id});
                        if ($dat->{action} eq 'subscribe') {
                            say STDERR "Subscribing to activity " . $dat->{activity_id};
                            $resp->{msg} = 'subscribed';
                            # todo emit event with recipient specified
                            $resp->{payload} = {
                                events => [{
                                    action => 'subscribed',
                                    who => $user,
                                    data => {
                                        activity => $activities->get($dat->{activity_id})
                                    }
                                }]
                            };
                            my $seconds = 0.1;
                            my $last_event = time;
                            $w = AnyEvent->timer(after => 0, interval => $seconds, cb => sub {
                                my $new_events = $events->find({timestamp => { '$gt' => $last_event }});

                                if (scalar @{$new_events} > 0) {
                                    $connection->send($json->encode({
                                        payload => {
                                            events => $new_events,
                                            activity => $activities->get($dat->{activity_id})
                                        },
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
                        } elsif ($dat->{action} eq 'reveal') {
                            say STDERR "Revealing " .  $dat->{payload}->{row} . ', ' . $dat->{payload}->{col};
                            $activities->set_phase($dat->{activity_id}, 'reveal', $dat->{payload});
                            $events->emitEvent($session->{data}->{user}->{_id}->value, $dat->{activity_id}, 'reveal', $dat->{payload});
                        } elsif ($dat->{action} eq 'daily_double') {
                            say STDERR "Daily Double! " .  $dat->{payload}->{row} . ', ' . $dat->{payload}->{col};
                            $events->emitEvent($session->{data}->{user}->{_id}->value, $dat->{activity_id}, 'daily_double', $dat->{payload});
                        } elsif ($dat->{action} eq 'buzz') {
                            if ($act->{state}->{phase} eq 'reveal') {
                                say STDERR "Buzz from " . $session->{data}->{user}->{username};
                                $activities->set_phase($dat->{activity_id}, 'answering', {
                                    user => $session->{data}->{user},
                                    row => $dat->{payload}->{current}->{row},
                                    col => $dat->{payload}->{current}->{col}
                                });
                                $dat->{payload}->{user} = $session->{data}->{user};
                                $events->emitEvent($session->{data}->{user}->{_id}->value, $dat->{activity_id}, 'buzz', $dat->{payload});
                            } else {
                                say STDERR "Can't buzz in during " . $act->{state}->{phase};
                                $resp->{msg} = 'Not in reveal state!';
                            }
                        } elsif ($dat->{action} eq 'accept_answer') {
                            if ($act->{state}->{phase} eq 'answering') {
                                $activities->set_phase($dat->{activity_id}, 'choosing', {});
                                $activities->award_score($dat->{activity_id}, $dat->{payload}->{current}->{user}, $dat->{payload}->{current}->{answer}->{value});
                                $activities->claim_answer($dat->{activity_id}, $dat->{payload}->{current}->{user}, $dat->{payload}->{current}->{row}, $dat->{payload}->{current}->{col});
                                $dat->{payload}->{user} = $dat->{payload}->{current}->{user};
                                $events->emitEvent($session->{data}->{user}->{_id}->value, $dat->{activity_id}, 'accept_answer', $dat->{payload});
                            } else {
                                $resp->{msg} = 'Not in answering state!';
                            }
                        } elsif ($dat->{action} eq 'wrong_answer') {
                            if ($act->{state}->{phase} eq 'answering') {
                                $dat->{payload}->{user} = $dat->{payload}->{current}->{user};
                                $activities->set_phase($dat->{activity_id}, 'reveal', {
                                    row => $dat->{payload}->{current}->{row},
                                    col => $dat->{payload}->{current}->{col}
                                }); #$dat->{payload});
                                $events->emitEvent($session->{data}->{user}->{_id}->value, $dat->{activity_id}, 'wrong_answer', $dat->{payload});
                            } else {
                                $resp->{msg} = 'Not in answering state!';
                            }
                        } elsif ($dat->{action} eq 'dismiss_answer') {
                            $activities->set_phase($dat->{activity_id}, 'choosing', { x => 1 });
                            $events->emitEvent($session->{data}->{user}->{_id}->value, $dat->{activity_id}, 'dismiss_answer', $dat->{payload});
                        } elsif ($dat->{action} eq 'kill_answer') {
                            $dat->{payload}->{current}->{user} = { username => false };
                            $activities->claim_answer($dat->{activity_id}, $dat->{payload}->{current}->{user}, $dat->{payload}->{current}->{row}, $dat->{payload}->{current}->{col});
                            
                            $events->emitEvent($session->{data}->{user}->{_id}->value, $dat->{activity_id}, 'kill_answer', $dat->{payload});
                        } elsif ($dat->{action} eq 'wager') {
                            p($dat);
                            say STDERR 'Wagered $' . $dat->{payload}->{wager} . '. Revealing ' .  $dat->{payload}->{row} . ', ' . $dat->{payload}->{col};
                            $events->emitEvent($session->{data}->{user}->{_id}->value, $dat->{activity_id}, 'reveal', $dat->{payload});
                            $activities->set_phase($dat->{activity_id}, 'reveal', $dat->{payload});
                        } else {
                            p($dat->{payload});
                            say STDERR "Unknown WebSocket Action: " .  $dat->{action};
                        }
                    }
                    if ($resp->{msg}) {
                        $resp->{activity} = $activities->get($dat->{activity_id});
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