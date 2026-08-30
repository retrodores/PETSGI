package PETSGI::Test::PETdiskMax;

use strict;
use warnings;
use MIME::Base64 qw(encode_base64);
use PETSGI::Protocol::PETdisk;
use Util::H2O::More qw(baptise);

sub new {
    my ($class, %args) = @_;
    my %self = (
        app       => $args{app} || die("app required\n"),
        client_id => $args{client_id} || 'mock-petdisk-max',
        block     => $args{block} || 512,
    );
    return baptise \%self, $class, qw(app client_id block);
}

sub _request {
    my ($self, %args) = @_;
    my $req = PETSGI::Protocol::PETdisk->normalize(
        %args,
        client_id => $self->client_id,
    );
    return $self->app->handle($req);
}

sub directory {
    my ($self) = @_;
    my @names;
    for (my $page = 0; ; $page++) {
        my $res = $self->_request(method => 'GET', query => {d => 1, p => $page});
        last if $res->body eq "\n";
        my @page_names = grep { length } split /\n/, $res->body;
        push @names, @page_names;
    }
    return @names;
}

sub load {
    my ($self, $name) = @_;
    my $stat = $self->_request(method => 'GET', query => {file => $name, l => 1});
    die "resource not found: $name\n" unless $stat->status == 200;
    my ($size) = $stat->body =~ /^(\d+)/;
    my $bytes = '';
    for (my $start = 0; $start < $size; $start += $self->block) {
        my $end = $start + $self->block;
        $end = $size if $end > $size;
        my $res = $self->_request(method => 'GET', query => {file => $name, s => $start, e => $end});
        $bytes .= $res->body;
    }
    return $bytes;
}

sub save {
    my ($self, $name, $bytes) = @_;
    my $first = 1;
    for (my $start = 0; $start < length($bytes) || ($first && !length($bytes)); $start += $self->block) {
        my $chunk = substr($bytes, $start, $self->block);
        my %query = (f => $name, b64 => 1);
        $query{n} = 1 if $first;
        my $res = $self->_request(
            method => 'PUT', query => \%query,
            body => encode_base64($chunk, ''),
        );
        die "save failed\n" unless $res->status == 200;
        $first = 0;
        last if !length($bytes);
    }
    return 1;
}

sub update {
    my ($self, $name, $start, $bytes) = @_;
    my $end = $start + length($bytes);
    my $res = $self->_request(
        method => 'PUT',
        query  => {f => $name, u => 1, s => $start, e => $end, b64 => 1},
        body   => encode_base64($bytes, ''),
    );
    return $res->status == 200;
}

1;
