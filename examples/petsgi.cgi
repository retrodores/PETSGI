#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use PETSGI;
use PETSGI::App::Files;

my $root = $ENV{PETSGI_ROOT} || '.';
PETSGI->run(app => PETSGI::App::Files->new(root => $root));
