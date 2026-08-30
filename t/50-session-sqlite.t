use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

BEGIN {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'DBI and DBD::SQLite are optional/recommended';
}
use PETSGI::Session::SQLite;

my $dir=tempdir(CLEANUP=>1);
my $s=PETSGI::Session::SQLite->new(path=>"$dir/petsgi.sqlite");
my $token=$s->identify('Brett');
like $token, qr/^[0-9A-F]{12}$/, 'compact application-layer token';
is $s->username($token), 'BRETT', 'claimed identity stored';
is $s->set($token,'screen','BOARD'), 'BOARD', 'state set';
is $s->get($token,'screen'), 'BOARD', 'state persists';

done_testing;
