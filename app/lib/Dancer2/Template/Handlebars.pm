package Dancer2::Template::Handlebars;

use lib '/opt/src/lib';

use 5.008005;
use strict;
use Data::Dumper;
use Data::Printer;

use Text::Handlebars;
use warnings FATAL => 'all';
use utf8;
use File::Slurp;
use JSON::XS;
use Number::Bytes::Human qw(format_bytes);
use POSIX;


use Moo;

use Dancer2::Core::Types 'InstanceOf';
use Dancer2::FileUtils 'path';
 
use Carp qw/croak/;
 
our $VERSION = 0.01; # VERSION

my $coder = JSON::XS->new->ascii->pretty->allow_nonref->convert_blessed;

# ABSTRACT: Text::Handlebars template engine wrapper for Dancer2
 
with 'Dancer2::Core::Role::Template';
 
has '+default_tmpl_ext' => ( default => sub { 'hbs' }          );
has '+engine'           => ( isa     => InstanceOf['Text::Handlebars']);

sub commafy {
   my ($self, $input) = @_;
   my $output = reverse $input;
   $output =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	 $output = reverse $output;
   return $output;
}



sub view_pathname {
  my ($self, $view) = @_;
 
  $view = $self->_template_name($view);
 
  return (ref $self->config->{path} eq 'HASH')  # virtual path
            ? $view
            : path($self->views, $view);
 
}
 
sub layout_pathname {
  my ($self, $layout) = @_;
 
  $layout = $self->_template_name($layout);
 
  return (ref $self->config->{path} eq 'HASH')  # virtual path
            ? path('layouts', $layout)
            : path($self->views, 'layouts', $layout);
}
 
sub render_layout {
    my ($self, $layout, $tokens, $content) = @_;
  
    $layout = $self->layout_pathname($layout);
 
    #$self->engine->escape_html(0);
  
    # FIXME: not sure if I can "just call render"
    $self->render( $layout, { %$tokens, content => $content } );
}
  
sub _build_engine {
    my $self = shift;
 
		return Text::Handlebars->new(
			helpers => {
				toJSON => sub {
					my ($context, $items, $options) = @_;

					return $coder->encode($items);
				},
				bytes => sub {
					my ($context, $bytes) = @_;
					return format_bytes($bytes);
				},
				daysOld => sub {
					my ($context, $timestamp) = @_;
					my $daysOld = $self->commafy(ceil((time - $timestamp) / 60 / 60 / 24));
					$daysOld = $daysOld;
				}
			}
		);
		
}
 
sub render {
    my ($self, $template_file, $vars) = @_;

		#croak Dumper($vars);
 
    my $handlebars = $self->engine;
		
		my $template = read_file($template_file);
		
    my $content = $handlebars->render_string($template, $vars)
      or croak $handlebars->error;
 
    # In the method layout set escape_html in 0 to insert the contents of a page
    # For all other cases set escape_html 1
 
    return $content;
}
 
1;
__END__