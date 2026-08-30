package PETSGI::Response;

use strict;
use warnings;
use Util::H2O::More qw(baptise);

sub new {
    my ($class, %args) = @_;
    my %self = (
        status       => $args{status} || 200,
        content_type => $args{content_type} || 'application/octet-stream',
        body         => defined $args{body} ? $args{body} : '',
        headers      => $args{headers} || {},
    );
    return baptise \%self, $class, qw(status content_type body headers);
}

sub ok    { return shift->new(status => 200, body => $_[0] // '') }
sub empty { return shift->new(status => 200, body => '') }

1;
