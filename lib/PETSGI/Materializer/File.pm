package PETSGI::Materializer::File;

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use Fcntl qw(:flock);
use Util::H2O::More qw(baptise);

sub new {
    my ($class, %args) = @_;
    my $root = $args{root} || File::Spec->catdir(File::Spec->tmpdir, 'petsgi-materialized');
    make_path($root) unless -d $root;
    my %self = (
        root => $root,
        ttl  => defined $args{ttl} ? $args{ttl} : 10,
    );
    return baptise \%self, $class, qw(root ttl);
}

sub get_or_create {
    my ($self, %args) = @_;
    my $key    = defined $args{key} ? $args{key} : die "key required\n";
    my $create = $args{create} || die "create callback required\n";
    my $refresh = $args{refresh} ? 1 : 0;

    my $hash = sha256_hex($key);
    my $path = File::Spec->catfile($self->root, $hash . '.bin');
    my $lock_path = File::Spec->catfile($self->root, $hash . '.lock');

    open my $lock, '>>', $lock_path or die "open $lock_path: $!\n";
    flock($lock, LOCK_EX) or die "flock $lock_path: $!\n";

    my $fresh = -f $path && (time - (stat($path))[9]) <= $self->ttl;
    if ($refresh || !$fresh) {
        my $bytes = $create->();
        $bytes = '' unless defined $bytes;
        my $tmp = $path . ".$$.tmp";
        open my $fh, '>:raw', $tmp or die "open $tmp: $!\n";
        print {$fh} $bytes;
        close $fh or die "close $tmp: $!\n";
        rename $tmp, $path or die "rename $tmp -> $path: $!\n";
    }

    open my $fh, '<:raw', $path or die "open $path: $!\n";
    local $/;
    my $bytes = <$fh>;
    close $fh;
    close $lock;
    return defined $bytes ? $bytes : '';
}

1;
