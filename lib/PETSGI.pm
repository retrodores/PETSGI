package PETSGI;

use strict;
use warnings;

our $VERSION = '0.01';

sub run {
    my ($class, %args) = @_;
    require PETSGI::Adapter::CGITiny;
    return PETSGI::Adapter::CGITiny->run(%args);
}

1;

__END__

=head1 NAME

PETSGI - PET Server Gateway Interface for stock PETdisk MAX clients

=head1 SYNOPSIS

  use PETSGI;
  use PETSGI::App::Files;

  PETSGI->run(
      app => PETSGI::App::Files->new(root => '/home/me/petfiles'),
  );

A full-stack application can expose executable views and lighter-weight SEQ
resources:

  use PETSGI::Application;

  my $app = PETSGI::Application->new(...);

  $app->view(
      name => 'HOME.PRG',
      render => sub {
          my ($ctx) = @_;
          return $ctx->ui
              ->title('MY PET APP')
              ->text('SERVER-RENDERED STATE');
      },
  );

=head1 DESCRIPTION

PETSGI turns the existing PETdisk MAX HTTP file protocol into an application
transport. The reference deployment is ordinary CGI via L<CGI::Tiny>, while
application code receives normalized PETSGI requests and is not tied to CGI.

The initial supported target is a 40-column Commodore PET using unmodified
PETdisk MAX firmware. The architecture separates target and transport so the
core is not intentionally locked to that combination.

Dynamic PRGs are treated as executable views of server-side application state.
SEQ resources may be used for polled state and submissions while a PRG remains
resident, and D64 remains available for mounted disk-style content.

=head1 APPLICATION MODEL

L<PETSGI::Application> provides both the low-level C<resource()> interface and
semantic C<view()> and C<action()> helpers. Callbacks for the
semantic API receive a L<PETSGI::Context> rather than a CGI or transport object.

L<PETSGI::UI::Screen> is the first 40-column semantic UI builder. It currently
renders to tokenized PET BASIC; later native/hybrid renderers are expected to
implement richer PET-local effects without changing application code.

=head1 SEE ALSO

L<PETSGI::Application>, L<PETSGI::Context>, L<PETSGI::UI::Screen>,
L<PETSGI::Protocol::PETdisk>, L<PETSGI::App::Files>

=cut
