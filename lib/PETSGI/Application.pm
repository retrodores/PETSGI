package PETSGI::Application;

use strict;
use warnings;
use Dispatch::Fu qw(dispatch on);
use Util::H2O::More qw(baptise);
use PETSGI::Resource;
use PETSGI::Response;

sub new {
    my ($class, %args) = @_;
    my %self = (
        resources    => {},
        fallback     => $args{fallback},
        materializer => $args{materializer},
    );
    return baptise \%self, $class, qw(resources fallback materializer);
}

sub resource {
    my ($self, %args) = @_;
    my $resource = PETSGI::Resource->new(%args);
    $self->resources->{$resource->name} = $resource;
    return $resource;
}

sub directory_names {
    my ($self) = @_;
    my @names = sort map { $_->name }
        grep { $_->listed } values %{ $self->resources };
    if ($self->fallback && $self->fallback->can('directory_names')) {
        push @names, $self->fallback->directory_names;
    }
    my %seen;
    return sort grep { !$seen{$_}++ } @names;
}

sub _page {
    my ($self, $page) = @_;
    my @pages = ('');
    for my $name ($self->directory_names) {
        my $entry = uc($name) . "\n";
        if (length($pages[-1]) + length($entry) >= 512) {
            $pages[-1] .= "\n";
            push @pages, '';
        }
        $pages[-1] .= $entry;
    }
    $pages[-1] .= "\n";
    return "\n" if $page > $#pages;
    return $pages[$page];
}

sub _bytes {
    my ($self, $resource, $req, $refresh) = @_;
    my $provider = $resource->read;
    if ($self->materializer) {
        my $key = join("\0", $req->client_id || '-', $resource->name);
        return $self->materializer->get_or_create(
            key     => $key,
            refresh => $refresh,
            create  => sub { $provider->($req, $self, $resource) },
        );
    }
    return $provider->($req, $self, $resource);
}

sub handle {
    my ($self, $req) = @_;
    my $resource = defined $req->resource
        ? $self->resources->{uc($req->resource)}
        : undef;

    if (!$resource && $req->operation ne 'DIRECTORY' && $self->fallback) {
        return $self->fallback->handle($req);
    }

    return dispatch {
        my $r = shift;
        return $r->operation;
    } $req,
      on DIRECTORY => sub {
          my $r = shift;
          return PETSGI::Response->new(body => $self->_page($r->page));
      },
      on STAT => sub {
          my $r = shift;
          return PETSGI::Response->new(status => 404) unless $resource;
          my $bytes = $self->_bytes($resource, $r, 1);
          return PETSGI::Response->new(body => length($bytes) . "\r\n");
      },
      on READ => sub {
          my $r = shift;
          return PETSGI::Response->new(status => 404) unless $resource;
          my $bytes = $self->_bytes($resource, $r, 0);
          my $start = $r->start || 0;
          if (defined $r->end && $r->end > 0) {
              my $len = $r->end - $start;
              return PETSGI::Response->new(status => 400) if $len < 0;
              $bytes = substr($bytes, $start, $len);
          }
          elsif ($start) {
              $bytes = substr($bytes, $start);
          }
          return PETSGI::Response->new(body => $bytes);
      },
      on CREATE => sub { return $self->_write_resource($resource, shift) },
      on APPEND => sub { return $self->_write_resource($resource, shift) },
      on UPDATE => sub { return $self->_write_resource($resource, shift) },
      on BAD_REQUEST => sub { return PETSGI::Response->new(status => 400) },
      on METHOD_NOT_ALLOWED => sub { return PETSGI::Response->new(status => 405) };
}

sub _write_resource {
    my ($self, $resource, $req) = @_;
    return PETSGI::Response->new(status => 404) unless $resource;
    my $writer = $resource->write;
    return PETSGI::Response->new(status => 405) unless ref($writer) eq 'CODE';
    $writer->($req, $self, $resource);
    return PETSGI::Response->new(body => '');
}

1;
