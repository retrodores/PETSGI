use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use PETSGI::App::Files;
use PETSGI::Test::PETdiskMax;

my $dir = tempdir(CLEANUP => 1);
sub put_file {
    my ($name,$bytes)=@_;
    open my $fh, '>:raw', File::Spec->catfile($dir,$name) or die $!;
    print {$fh} $bytes;
    close $fh;
}
put_file('hello.prg', "\x01\x04HELLO");
put_file('notes.seq', "ONE\nTWO\n");
put_file('disk.d64', 'D' x 2048);
put_file('ignored.txt', 'no');

my $app = PETSGI::App::Files->new(root => $dir);
my $pet = PETSGI::Test::PETdiskMax->new(app => $app);

is_deeply [ $pet->directory ], [qw(DISK.D64 HELLO.PRG NOTES.SEQ)], 'PHP-compatible extensions listed';
is $pet->load('HELLO.PRG'), "\x01\x04HELLO", 'case-insensitive PRG load';
is length($pet->load('DISK.D64')), 2048, 'multi-block D64 read';

ok $pet->save('SAVE.SEQ', 'A' x 700), 'save over first/append PUTs';
is $pet->load('SAVE.SEQ'), 'A' x 700, 'saved data round trips';

ok $pet->update('DISK.D64', 510, 'XYZ'), 'range update';
my $d = $pet->load('DISK.D64');
is substr($d,510,3), 'XYZ', 'D64 bytes updated in place';

my $bad = PETSGI::Request->new(operation=>'STAT',resource=>'../secret');
is $app->handle($bad)->status, 404, 'path traversal is not exposed';

my $time = $pet->load('TIME');
like $time, qr/^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\n$/, 'TIME pseudo-resource';

done_testing;
