package PETSGI::Adapter::CGITiny;

use strict;
use warnings;
use CGI::Tiny;
use PETSGI::Protocol::PETdisk;

sub run {
    my ($class, %args) = @_;
    my $app = $args{app} || die "app required\n";

    cgi {
        my $cgi = $_;
        $cgi->set_request_body_limit($args{body_limit} || 16 * 1024 * 1024);
        $cgi->set_error_handler(sub {
            my ($c, $error, $rendered) = @_;
            warn $error;
            $c->set_response_status(500)->render(data => '') unless $rendered;
        });

        my %query;
        for my $name (@{ $cgi->query_param_names }) {
            $query{$name} = $cgi->query_param($name);
        }

        my $body = $cgi->method eq 'PUT' ? $cgi->body : '';
        my $req = PETSGI::Protocol::PETdisk->normalize(
            method    => $cgi->method,
            query     => \%query,
            body      => $body,
            client_id => $cgi->remote_addr || '',
        );
        my $res = $app->handle($req);

        $cgi->set_response_status($res->status);
        $cgi->set_response_type($res->content_type);
        while (my ($name, $value) = each %{ $res->headers }) {
            $cgi->add_response_header($name => $value);
        }
        $cgi->render(data => $res->body);
    };
    return;
}

1;
