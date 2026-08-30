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

=head1 DESCRIPTION

PETSGI turns the existing PETdisk MAX HTTP file protocol into an application
transport.  The reference deployment is ordinary CGI via L<CGI::Tiny>, while
application code receives normalized PETSGI requests and is not tied to CGI.

The initial supported target is a 40-column Commodore PET using unmodified
PETdisk MAX firmware.  The architecture separates target and transport so the
core is not intentionally locked to that combination.

=cut
