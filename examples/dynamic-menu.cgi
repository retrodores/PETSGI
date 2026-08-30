#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use PETSGI;
use PETSGI::Application;
use PETSGI::App::Files;
use PETSGI::BASIC::Program;
use PETSGI::Materializer::File;

my $root = $ENV{PETSGI_ROOT} || '.';
my $files = PETSGI::App::Files->new(root => $root);
my $app = PETSGI::Application->new(
    fallback => $files,
    materializer => PETSGI::Materializer::File->new(
        root => $ENV{PETSGI_CACHE} || "$root/.petsgi-cache",
    ),
);

$app->resource(
    name => 'MENU.PRG',
    type => 'PRG',
    read => sub {
        my $p = PETSGI::BASIC::Program->new;
        $p->clear_screen(10)
          ->print_line(20, 'PETSGI DYNAMIC MENU')
          ->print_line(30, '40-COLUMN PET TARGET')
          ->print_line(40, '')
          ->print_line(50, 'THIS PRG WAS GENERATED')
          ->print_line(60, 'BY THE SERVER.')
          ->line(70, 'END');
        return $p->prg;
    },
);

PETSGI->run(app => $app);
