requires 'perl', '5.016';
requires 'CGI::Tiny', '1.003';
requires 'Dispatch::Fu', '1.06';
requires 'Util::H2O::More', '0.4.3';
requires 'MIME::Base64';
requires 'Digest::SHA';

recommends 'DBI';
recommends 'DBD::SQLite';

on test => sub {
    requires 'Test::More';
    requires 'File::Temp';
};
