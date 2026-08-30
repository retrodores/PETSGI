use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use PETSGI::Application;
use PETSGI::BASIC::Program;
use PETSGI::Materializer::File;
use PETSGI::Target::PET40;
use PETSGI::Test::PETdiskMax;

my $target = PETSGI::Target::PET40->new;
is $target->columns, 40, 'initial supported target is 40 columns';
is $target->basic_start, 0x0401, 'PET BASIC load address';

my $calls = 0;
my $cache = tempdir(CLEANUP => 1);
my $app = PETSGI::Application->new(
    materializer => PETSGI::Materializer::File->new(root=>$cache, ttl=>30),
);
$app->resource(
    name=>'MENU.PRG', type=>'PRG',
    read=>sub {
        $calls++;
        my $p=PETSGI::BASIC::Program->new(start=>$target->basic_start);
        $p->clear_screen(10)
          ->print_line(20,'PETSGI MENU')
          ->print_line(30,'1 BBS')
          ->print_line(40,'2 AVE MARIA')
          ->line(50,'END');
        return $p->prg;
    },
);

my $pet = PETSGI::Test::PETdiskMax->new(app=>$app, block=>17, client_id=>'PET-A');
my $prg = $pet->load('MENU.PRG');
is $calls, 1, 'STAT materializes once and range reads use frozen PRG';
is unpack('v',substr($prg,0,2)), 0x0401, 'valid PRG load address';
ok index($prg, chr(0x99)) >= 0, 'PRINT token emitted';
ok index($prg, 'PETSGI MENU') >= 0, 'dynamic state embedded in executable';

my $again = $pet->load('MENU.PRG');
is $calls, 2, 'next LOAD gets a newly materialized application state';
is $again, $prg, 'same state produces same executable';

done_testing;
