use strict;
use warnings;
use Test::More;

use_ok 'PETSGI';
use_ok 'PETSGI::Request';
use_ok 'PETSGI::Response';
use_ok 'PETSGI::Protocol::PETdisk';
use_ok 'PETSGI::Application';
use_ok 'PETSGI::Context';
use_ok 'PETSGI::App::Files';
use_ok 'PETSGI::Materializer::File';
use_ok 'PETSGI::Target::PET40';
use_ok 'PETSGI::BASIC::Program';
use_ok 'PETSGI::UI::Screen';
use_ok 'PETSGI::Test::PETdiskMax';

done_testing;
