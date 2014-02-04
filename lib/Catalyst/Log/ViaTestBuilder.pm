package Catalyst::Log::ViaTestBuilder;
# ABSTRACT: sends log messages to Test::Builder

our $VERSION = '0.03';

use 5.010;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Log';

has app_ident => (
  is => 'rw',
  isa => 'Str',
  default => '',
);

has prefix_msg => (
  is => 'rw',
  isa => 'CodeRef',
  default => sub{ sub{
    my ( $self, $lvl, $continuation ) = @_;
    return sprintf(
      '%s%s%5s%s ',
      ( $continuation ? qq{\n} : qq{} ),
      $self->app_ident,
      uc $lvl,
      ( $continuation ? '>' : ']' ),
    );
  }},
);

around new => sub {
  my ( $orig, $class, @args ) = @_;
  my $self = $class->$orig( grep{ not ref } @args );
  if ( ref $args[0] eq 'HASH' ) {
    $self->$_( $args[0]->{ $_ }) for ( keys %{$args[0]} );
  }
  return $self;
};

sub _log {
  my $self  = shift;
  my $level = shift;
  my $test  = Test::Builder->new;
  my $out   = $test->can( $level =~ /^(?:debug|info)$/ ? 'note' : 'diag' );

  my $message = join( $self->prefix_msg->( $self, $level, 1 ), @_ );
  $message .= "\n" unless $message =~ /\n$/;
  $out->( $test, $self->prefix_msg->( $self, $level ) . $message );
}

# safety fall-back
sub _send_to_log {
  my $self = shift;
  my $test = Test::Builder->new;
  $test->diag( @_ );
}

1;
