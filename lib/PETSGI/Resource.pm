package PETSGI::Resource;

use strict;
use warnings;
use Util::H2O::More qw(baptise);

sub new {
    my ($class, %args) = @_;
    die "resource name required\n" unless defined $args{name} && length $args{name};
    die "read callback required\n" unless ref($args{read}) eq 'CODE';
    my %self = (
        name   => uc($args{name}),
        type   => uc($args{type} || 'SEQ'),
        role   => uc($args{role} || 'RESOURCE'),
        read   => $args{read},
        write  => $args{write},
        listed => exists $args{listed} ? !!$args{listed} : 1,
    );
    return baptise \%self, $class, qw(name type role read write listed);
}

1;
