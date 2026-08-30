#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use PETSGI;
use PETSGI::Application;
use PETSGI::Materializer::File;

my $root = $ENV{PETSGI_ROOT} || '.';
my $app = PETSGI::Application->new(
    materializer => PETSGI::Materializer::File->new(
        root => $ENV{PETSGI_CACHE} || "$root/.petsgi-cache",
    ),
);

$app->view(
    name => 'HOME.PRG',
    render => sub {
        my ($ctx) = @_;
        return $ctx->ui
            ->title('PETSGI')
            ->blank
            ->text('SERVER-RENDERED PET UX')
            ->blank
            ->menu(
                { label => 'MESSAGE BOARD', route => 'BOARD.PRG' },
                { label => 'CHAT',          route => 'CHAT.PRG'  },
                { label => 'FILES',         route => 'FILES.PRG' },
            )
            ->status('PET-FIRST, NOT PET-LOCKED');
    },
);

$app->resource(
    name => 'STATUS.SEQ',
    type => 'SEQ',
    role => 'STATE',
    listed => 0,
    read => sub {
        return "ONLINE=1\n";
    },
);

$app->action(
    name => 'ACTION.SEQ',
    listed => 0,
    write => sub {
        my ($ctx, $bytes, $operation) = @_;
        # Stock PETdisk invokes this once per 512-byte PUT block. Applications
        # that need transactions larger than one block should frame/commit them.
        warn "PETSGI action $operation: $bytes\n";
    },
);

PETSGI->run(app => $app);
