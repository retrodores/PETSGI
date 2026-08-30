package PETSGI::Target::PET40;

use strict;
use warnings;
use Util::H2O::More qw(baptise);

sub new {
    my ($class, %args) = @_;
    my %self = (
        name        => 'Commodore PET 40-column',
        columns     => 40,
        rows        => 25,
        basic_start => 0x0401,
        cpu         => '6502',
    );
    return baptise \%self, $class, qw(name columns rows basic_start cpu);
}

1;
