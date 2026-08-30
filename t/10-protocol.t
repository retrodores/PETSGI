use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64);
use PETSGI::Protocol::PETdisk;

sub norm { PETSGI::Protocol::PETdisk->normalize(@_) }

is norm(method=>'GET', query=>{d=>1,p=>2})->operation, 'DIRECTORY', 'directory';
is norm(method=>'GET', query=>{d=>1,p=>2})->page, 2, 'page';
is norm(method=>'GET', query=>{file=>'X.PRG',l=>1})->operation, 'STAT', 'stat';
my $r = norm(method=>'GET', query=>{file=>'X.PRG',s=>512,e=>1024});
is $r->operation, 'READ', 'read';
is $r->start, 512, 'range start';
is $r->end, 1024, 'range end';
is norm(method=>'PUT', query=>{f=>'X.SEQ',n=>1,b64=>1}, body=>encode_base64('abc',''))->operation, 'CREATE', 'create';
is norm(method=>'PUT', query=>{f=>'X.SEQ'}, body=>'def')->operation, 'APPEND', 'append';
is norm(method=>'PUT', query=>{f=>'X.D64',u=>1,s=>4,e=>7}, body=>'xyz')->operation, 'UPDATE', 'update';
is norm(method=>'PUT', query=>{f=>'X.SEQ',n=>1,b64=>1}, body=>encode_base64('abc',''))->body, 'abc', 'base64 decoded';
is norm(method=>'DELETE', query=>{})->operation, 'METHOD_NOT_ALLOWED', 'unsupported method';

done_testing;
