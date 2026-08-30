package PETSGI::Protocol::PETdisk;

use strict;
use warnings;
use MIME::Base64 qw(decode_base64);
use PETSGI::Request;

sub normalize {
    my ($class, %args) = @_;

    my $method = uc($args{method} || 'GET');
    my $query  = $args{query} || {};
    my $body   = defined $args{body} ? $args{body} : '';

    if ($method eq 'PUT' && $query->{b64}) {
        $body = decode_base64($body);
    }

    my ($operation, $resource, $page, $start, $end);

    if ($method eq 'GET') {
        if (defined $query->{d} && $query->{d} eq '1') {
            $operation = 'DIRECTORY';
            $page = (defined $query->{p} && $query->{p} =~ /^\d+$/) ? 0 + $query->{p} : 0;
        }
        elsif (defined $query->{file} && defined $query->{l} && $query->{l} eq '1') {
            $operation = 'STAT';
            $resource = $query->{file};
        }
        elsif (defined $query->{file}) {
            $operation = 'READ';
            $resource = $query->{file};
            $start = (defined $query->{s} && $query->{s} =~ /^\d+$/) ? 0 + $query->{s} : 0;
            $end   = (defined $query->{e} && $query->{e} =~ /^\d+$/) ? 0 + $query->{e} : undef;
        }
        else {
            $operation = 'BAD_REQUEST';
        }
    }
    elsif ($method eq 'PUT') {
        $resource = $query->{f};
        if (!defined $resource || !length $resource) {
            $operation = 'BAD_REQUEST';
        }
        elsif (defined $query->{u} && $query->{u} eq '1') {
            $operation = 'UPDATE';
            $start = (defined $query->{s} && $query->{s} =~ /^\d+$/) ? 0 + $query->{s} : 0;
            $end   = (defined $query->{e} && $query->{e} =~ /^\d+$/) ? 0 + $query->{e} : undef;
        }
        elsif (defined $query->{n} && $query->{n} eq '1') {
            $operation = 'CREATE';
        }
        else {
            $operation = 'APPEND';
        }
    }
    else {
        $operation = 'METHOD_NOT_ALLOWED';
    }

    return PETSGI::Request->new(
        method    => $method,
        operation => $operation,
        resource  => $resource,
        page      => defined $page ? $page : 0,
        start     => defined $start ? $start : 0,
        end       => $end,
        body      => $body,
        query     => $query,
        client_id => $args{client_id} || '',
    );
}

1;
