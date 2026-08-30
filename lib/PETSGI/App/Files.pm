package PETSGI::App::Files;

use strict;
use warnings;
use Dispatch::Fu qw(dispatch on);
use File::Spec;
use POSIX qw(strftime);
use Util::H2O::More qw(baptise);
use PETSGI::Response;

sub new {
    my ($class, %args) = @_;
    my $root = $args{root} || '.';
    die "root is not a directory: $root\n" unless -d $root;
    my %self = (
        root      => $root,
        read_only => $args{read_only} ? 1 : 0,
    );
    return baptise \%self, $class, qw(root read_only);
}

sub _valid_name {
    my ($self, $name) = @_;
    return 0 unless defined $name && length $name;
    return 0 if $name eq '.' || $name eq '..';
    return 0 if $name =~ m{[/\\\0]};
    return 1;
}

sub _find {
    my ($self, $name) = @_;
    return unless $self->_valid_name($name);
    my $exact = File::Spec->catfile($self->root, $name);
    return $exact if -f $exact;
    opendir my $dh, $self->root or return;
    my ($match) = grep { lc($_) eq lc($name) && -f File::Spec->catfile($self->root, $_) } readdir $dh;
    closedir $dh;
    return defined $match ? File::Spec->catfile($self->root, $match) : undef;
}

sub directory_names {
    my ($self) = @_;
    opendir my $dh, $self->root or return;
    my @names = sort map { uc($_) }
        grep { /\.(?:prg|seq|d64)\z/i && -f File::Spec->catfile($self->root, $_) }
        readdir $dh;
    closedir $dh;
    return @names;
}

sub _page {
    my ($self, $page) = @_;
    my @pages = ('');
    for my $name ($self->directory_names) {
        my $entry = $name . "\n";
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

sub handle {
    my ($self, $req) = @_;
    return dispatch {
        my $r = shift;
        return $r->operation;
    } $req,
      on DIRECTORY => sub {
          my $r = shift;
          return PETSGI::Response->new(body => $self->_page($r->page));
      },
      on STAT => sub { return $self->_stat(shift) },
      on READ => sub { return $self->_read(shift) },
      on CREATE => sub { return $self->_write(shift, 'create') },
      on APPEND => sub { return $self->_write(shift, 'append') },
      on UPDATE => sub { return $self->_write(shift, 'update') },
      on BAD_REQUEST => sub { return PETSGI::Response->new(status => 400) },
      on METHOD_NOT_ALLOWED => sub { return PETSGI::Response->new(status => 405) };
}

sub _stat {
    my ($self, $req) = @_;
    if (defined $req->resource && $req->resource eq 'TIME') {
        return PETSGI::Response->new(body => "20\r\n");
    }
    my $path = $self->_find($req->resource);
    return PETSGI::Response->new(status => 404) unless $path;
    return PETSGI::Response->new(body => (-s $path) . "\r\n");
}

sub _read {
    my ($self, $req) = @_;
    if (defined $req->resource && $req->resource eq 'TIME') {
        return PETSGI::Response->new(body => strftime("%Y-%m-%d %H:%M:%S\n", gmtime));
    }
    my $path = $self->_find($req->resource);
    return PETSGI::Response->new(status => 404) unless $path;
    open my $fh, '<:raw', $path or return PETSGI::Response->new(status => 500);
    my $start = $req->start || 0;
    seek($fh, $start, 0) or return PETSGI::Response->new(status => 500);
    my $bytes = '';
    if (defined $req->end && $req->end > 0) {
        my $len = $req->end - $start;
        return PETSGI::Response->new(status => 400) if $len < 0;
        read($fh, $bytes, $len);
    }
    else {
        local $/;
        $bytes = <$fh>;
        $bytes = '' unless defined $bytes;
    }
    close $fh;
    return PETSGI::Response->new(body => $bytes);
}

sub _write {
    my ($self, $req, $mode) = @_;
    return PETSGI::Response->new(body => '') if $self->read_only;
    return PETSGI::Response->new(status => 400) unless $self->_valid_name($req->resource);

    if ($mode eq 'update') {
        my $path = $self->_find($req->resource);
        return PETSGI::Response->new(status => 404) unless $path;
        return PETSGI::Response->new(status => 400) unless defined $req->end && $req->end >= $req->start;
        my $len = $req->end - $req->start;
        my $data = substr($req->body, 0, $len);
        open my $fh, '+<:raw', $path or return PETSGI::Response->new(status => 500);
        flock($fh, 2);
        seek($fh, $req->start, 0) or return PETSGI::Response->new(status => 500);
        print {$fh} $data;
        close $fh;
        return PETSGI::Response->new(body => '');
    }

    my $path = File::Spec->catfile($self->root, $req->resource);
    my $open_mode = $mode eq 'create' ? '>:raw' : '>>:raw';
    open my $fh, $open_mode, $path or return PETSGI::Response->new(status => 500);
    flock($fh, 2);
    print {$fh} $req->body;
    close $fh;
    return PETSGI::Response->new(body => '');
}

1;
