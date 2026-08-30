use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'PETSGI',
    VERSION_FROM  => 'lib/PETSGI.pm',
    ABSTRACT      => 'PET Server Gateway Interface for PETdisk MAX applications',
    AUTHOR        => 'PETSGI contributors',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM     => {
        'CGI::Tiny'       => '1.003',
        'Dispatch::Fu'    => '1.06',
        'Util::H2O::More' => '0.4.3',
        'MIME::Base64'    => 0,
        'Digest::SHA'     => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'File::Temp' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                recommends => {
                    DBI           => 0,
                    'DBD::SQLite' => 0,
                },
            },
        },
    },
);
