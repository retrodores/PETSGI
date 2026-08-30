use strict;
use warnings;
use Test::More;
use PETSGI::BASIC::Program;

my $p=PETSGI::BASIC::Program->new;
$p->line(10,'A=1+2')
  ->line(20,'IF A>2 THEN PRINT "OK"')
  ->line(30,'END');
my $prg=$p->prg;
is unpack('v',substr($prg,0,2)), 0x0401, 'PRG begins at PET BASIC address';
ok index($prg,chr(0xB2)) >= 0, '= token';
ok index($prg,chr(0xAA)) >= 0, '+ token';
ok index($prg,chr(0x8B)) >= 0, 'IF token';
ok index($prg,chr(0xA7)) >= 0, 'THEN token';
ok index($prg,chr(0x99)) >= 0, 'PRINT token';
my $first_next = unpack('v', substr($prg,2,2));
ok $first_next > 0x0401, 'first BASIC link points forward';
my $first_offset = 2 + ($first_next - 0x0401);
is unpack('v', substr($prg,$first_offset,2)) > $first_next, 1, 'second BASIC link also points forward';
like $p->source, qr/^10 A=1\+2/m, 'human-readable source retained';

done_testing;
