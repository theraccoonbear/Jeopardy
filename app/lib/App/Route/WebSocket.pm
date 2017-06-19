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
use App::Model::User;
use App::Model::Game;
use App::Model::Activity;

my $users = App::Model::User->new();
my $games = App::Model::Game->new();
my $activities = App::Model::Activity->new();

# prefix '/websocket';

# get q{/} => sub {
#     say STDERR "Websocket here!";
#     return Plack::App::WebSocket->new(
#         on_error => sub {
#             my $env = shift;
#             return [500,
#                     ["Content-Type" => "text/plain"],
#                     ["Error: " . $env->{"plack.app.websocket.error"}]];
#         },
#         on_establish => sub {
#             my $conn = shift; ## Plack::App::WebSocket::Connection object
#             my $env = shift;  ## PSGI env
#             $conn->on(
#                 message => sub {
#                     my ($connection, $msg) = @_;
#                     my $dat = decode_json($msg);
#                     p($dat);
#                     if ($dat->{action}) {
#                         if ($dat->{action} eq 'reveal') {
#                             $dat = {
#                                 msg => ("Revealing: " . $dat->{catIdx} . ":" . $dat->{rowIdx})
#                             };
#                         }
#                     } else {
#                         $dat->{msg} .= ' PING!';
#                     }
#                     p($dat);
#                     $connection->send(encode_json($dat));
#                 },
#                 finish => sub {
#                     undef $conn;
#                     warn "Bye!!\n";
#                 },
#             );
#         }
#     )->to_app;
# };