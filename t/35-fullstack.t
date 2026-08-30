use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use PETSGI::Application;
use PETSGI::Materializer::File;
use PETSGI::Test::PETdiskMax;

my $cache = tempdir(CLEANUP => 1);
my $app = PETSGI::Application->new(
    materializer => PETSGI::Materializer::File->new(root => $cache),
);

my ($view_calls, $state_calls, @actions) = (0, 0);
$app->view(
    name => 'HOME.PRG',
    render => sub {
        my ($ctx) = @_;
        $view_calls++;
        is $ctx->target->columns, 40, 'view context carries PET40 target';
        return $ctx->ui
            ->title('PETSGI APP')
            ->text('HELLO FROM SERVER STATE')
            ->menu(
                { label => 'BOARD', route => 'BOARD.PRG' },
                { label => 'CHAT',  route => 'CHAT.PRG'  },
            );
    },
);
$app->resource(
    name => 'STATE.SEQ',
    type => 'SEQ',
    role => 'STATE',
    read => sub {
        $state_calls++;
        return "COUNT=$state_calls\n";
    },
);
$app->action(
    name => 'DO.SEQ',
    write => sub {
        my ($ctx, $bytes, $operation) = @_;
        push @actions, [$operation, $bytes];
    },
);

is $app->resources->{'HOME.PRG'}->role, 'VIEW', 'view has semantic role';
is $app->resources->{'STATE.SEQ'}->role, 'STATE', 'dynamic SEQ may carry an application role';
is $app->resources->{'DO.SEQ'}->role, 'ACTION', 'action has semantic role';

my $pet = PETSGI::Test::PETdiskMax->new(app => $app, block => 29, client_id => 'PET-A');
my $prg = $pet->load('HOME.PRG');
is $view_calls, 1, 'executable view materialized once per load';
is unpack('v', substr($prg, 0, 2)), 0x0401, 'view compiles to PET PRG';
ok index($prg, 'PETSGI APP') >= 0, 'server state appears in executable view';

is $pet->load('STATE.SEQ'), "COUNT=1\n", 'dynamic SEQ returns current state';
is $pet->load('STATE.SEQ'), "COUNT=2\n", 'next load refreshes dynamic SEQ state';

ok $pet->save('DO.SEQ', 'ABC'), 'action accepts PETdisk write';
is_deeply $actions[0], ['CREATE', 'ABC'], 'action receives operation and body';

done_testing;
