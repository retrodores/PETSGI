use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use PETSGI::Application;
use PETSGI::App::Files;
use PETSGI::Materializer::File;
use PETSGI::Test::PETdiskMax;

my $dir=tempdir(CLEANUP=>1);
open my $fh,'>:raw',"$dir/HELLO.PRG" or die $!; print {$fh} 'HELLO'; close $fh;
my $app=PETSGI::Application->new(
    fallback=>PETSGI::App::Files->new(root=>$dir),
    materializer=>PETSGI::Materializer::File->new(root=>"$dir/cache"),
);
$app->resource(name=>'NEWS.SEQ',type=>'SEQ',read=>sub{"LIVE NEWS\n"});
my $pet=PETSGI::Test::PETdiskMax->new(app=>$app);

is_deeply [ $pet->directory ], [qw(HELLO.PRG NEWS.SEQ)], 'virtual and filesystem resources coalesce';
is $pet->load('NEWS.SEQ'), "LIVE NEWS\n", 'dynamic SEQ';
is $pet->load('HELLO.PRG'), 'HELLO', 'fallback regular file';

done_testing;
