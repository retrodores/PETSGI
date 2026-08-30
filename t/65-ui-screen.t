use strict;
use warnings;
use Test::More;
use PETSGI::Target::PET40;
use PETSGI::UI::Screen;

my $ui = PETSGI::UI::Screen->new(target => PETSGI::Target::PET40->new);
$ui->title('PETSGI BBS')
   ->text('WELCOME BRETT')
   ->blank
   ->menu(
       { label => 'MESSAGES', route => 'BOARD.PRG' },
       { label => 'CHAT',     route => 'CHAT.PRG' },
   )
   ->status('UP/DOWN + RETURN');

my @lines = $ui->lines;
ok @lines <= 25, 'screen never exceeds PET rows';
ok !grep { length($_) > 40 } @lines, 'screen never exceeds 40 columns';
like $ui->as_text, qr/PETSGI BBS/, 'text renderer exposes title';
like $ui->as_text, qr/ 1\. MESSAGES/, 'menu is represented semantically';
is $lines[-1], 'UP/DOWN + RETURN', 'status is placed on final row';

my $prg = $ui->prg;
is unpack('v', substr($prg, 0, 2)), 0x0401, 'UI compiles to PET BASIC PRG';
ok index($prg, 'WELCOME BRETT') >= 0, 'UI content is embedded in executable';
like $ui->basic_program->source, qr/PRINT "UP\/DOWN \+ RETURN";/, 'final screen row does not force a scroll';

done_testing;
