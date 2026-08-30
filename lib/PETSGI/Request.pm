package PETSGI::Request;

use strict;
use warnings;
use Util::H2O::More qw(baptise);

sub new {
    my ($class, %args) = @_;
    my %self = (
        method    => $args{method}    || 'GET',
        operation => $args{operation} || '',
        resource  => $args{resource},
        page      => defined $args{page}  ? $args{page}  : 0,
        start     => defined $args{start} ? $args{start} : 0,
        end       => $args{end},
        body      => defined $args{body} ? $args{body} : '',
        query     => $args{query} || {},
        client_id => defined $args{client_id} ? $args{client_id} : '',
    );
    return baptise \%self, $class,
        qw(method operation resource page start end body query client_id);
}

1;
