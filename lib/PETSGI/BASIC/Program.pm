package PETSGI::BASIC::Program;

use strict;
use warnings;
use Util::H2O::More qw(baptise);

my %TOKEN = (
    'END'     => 0x80, 'FOR'    => 0x81, 'NEXT'   => 0x82,
    'DATA'    => 0x83, 'INPUT#' => 0x84, 'INPUT'  => 0x85,
    'DIM'     => 0x86, 'READ'   => 0x87, 'LET'    => 0x88,
    'GOTO'    => 0x89, 'RUN'    => 0x8A, 'IF'     => 0x8B,
    'RESTORE' => 0x8C, 'GOSUB'  => 0x8D, 'RETURN' => 0x8E,
    'REM'     => 0x8F, 'STOP'   => 0x90, 'ON'     => 0x91,
    'WAIT'    => 0x92, 'LOAD'   => 0x93, 'SAVE'   => 0x94,
    'VERIFY'  => 0x95, 'DEF'    => 0x96, 'POKE'   => 0x97,
    'PRINT#'  => 0x98, 'PRINT'  => 0x99, 'CONT'   => 0x9A,
    'LIST'    => 0x9B, 'CLR'    => 0x9C, 'CMD'    => 0x9D,
    'SYS'     => 0x9E, 'OPEN'   => 0x9F, 'CLOSE'  => 0xA0,
    'GET'     => 0xA1, 'NEW'    => 0xA2, 'TAB('   => 0xA3,
    'TO'      => 0xA4, 'FN'     => 0xA5, 'SPC('   => 0xA6,
    'THEN'    => 0xA7, 'NOT'    => 0xA8, 'STEP'   => 0xA9,
    '+'       => 0xAA, '-'      => 0xAB, '*'      => 0xAC,
    '/'       => 0xAD, '^'      => 0xAE, 'AND'    => 0xAF,
    'OR'      => 0xB0, '>'      => 0xB1, '='      => 0xB2,
    '<'       => 0xB3, 'SGN'    => 0xB4,
    'INT'     => 0xB5, 'ABS'    => 0xB6, 'USR'    => 0xB7,
    'FRE'     => 0xB8, 'POS'    => 0xB9, 'SQR'    => 0xBA,
    'RND'     => 0xBB, 'LOG'    => 0xBC, 'EXP'    => 0xBD,
    'COS'     => 0xBE, 'SIN'    => 0xBF, 'TAN'    => 0xC0,
    'ATN'     => 0xC1, 'PEEK'   => 0xC2, 'LEN'    => 0xC3,
    'STR$'    => 0xC4, 'VAL'    => 0xC5, 'ASC'    => 0xC6,
    'CHR$'    => 0xC7, 'LEFT$'  => 0xC8, 'RIGHT$' => 0xC9,
    'MID$'    => 0xCA, 'GO'     => 0xCB,
);
my @KEYWORDS = sort { length($b) <=> length($a) } keys %TOKEN;

sub new {
    my ($class, %args) = @_;
    my %self = (
        start => defined $args{start} ? $args{start} : 0x0401,
        lines => [],
    );
    return baptise \%self, $class, qw(start lines);
}

sub line {
    my ($self, $number, $text) = @_;
    die "invalid BASIC line number\n" unless defined $number && $number =~ /^\d+$/ && $number <= 63999;
    push @{ $self->lines }, [0 + $number, defined $text ? $text : ''];
    return $self;
}

sub clear_screen {
    my ($self, $number) = @_;
    return $self->line($number, 'PRINT CHR$(147)');
}

sub print_line {
    my ($self, $number, $text) = @_;
    $text = '' unless defined $text;
    $text =~ s/"/""/g;
    return $self->line($number, qq{PRINT "$text"});
}

sub source {
    my ($self) = @_;
    return join('', map { $_->[0] . ' ' . $_->[1] . "\n" } sort { $a->[0] <=> $b->[0] } @{ $self->lines });
}

sub _tokenize {
    my ($self, $text) = @_;
    my $out = '';
    my $quoted = 0;
    my $rem = 0;
    my $i = 0;
    while ($i < length $text) {
        my $ch = substr($text, $i, 1);
        if ($ch eq '"') {
            $quoted = !$quoted;
            $out .= $ch;
            $i++;
            next;
        }
        if (!$quoted && !$rem) {
            my $rest = substr($text, $i);
            my $matched;
            for my $kw (@KEYWORDS) {
                if (index(uc($rest), $kw) == 0) {
                    $out .= chr($TOKEN{$kw});
                    $i += length($kw);
                    $rem = 1 if $kw eq 'REM';
                    $matched = 1;
                    last;
                }
            }
            next if $matched;
        }
        $out .= $ch;
        $i++;
    }
    return $out;
}

sub prg {
    my ($self) = @_;
    my @lines = sort { $a->[0] <=> $b->[0] } @{ $self->lines };
    my $addr = $self->start;
    my $body = '';
    for my $line (@lines) {
        my ($number, $text) = @$line;
        my $tokens = $self->_tokenize($text);
        my $record_len = 2 + 2 + length($tokens) + 1;
        my $next = $addr + $record_len;
        $body .= pack('v', $next) . pack('v', $number) . $tokens . "\0";
        $addr = $next;
    }
    $body .= "\0\0";
    return pack('v', $self->start) . $body;
}

1;
