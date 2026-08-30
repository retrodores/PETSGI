use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

BEGIN {
    eval { require CGI::Tiny; 1 }
        or plan skip_all => 'CGI::Tiny required for adapter integration test';
}

my $dir=tempdir(CLEANUP=>1);
open my $fh,'>:raw',"$dir/HELLO.PRG" or die $!;
print {$fh} 'HELLO';
close $fh;

local $ENV{PETSGI_ROOT}=$dir;
open my $pipe, '-|', $^X, 'examples/petsgi.cgi', 'get', '/?file=HELLO.PRG&l=1'
    or die "run CGI example: $!";
local $/;
my $out=<$pipe>;
close $pipe;
is $?,0,'CGI example exits successfully';
is $out,"5\r\n",'CGI::Tiny debug request reaches PETSGI file app';

done_testing;
