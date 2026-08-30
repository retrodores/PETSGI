package PETSGI::UI::Screen;

use strict;
use warnings;
use Util::H2O::More qw(baptise);
use PETSGI::Target::PET40;
use PETSGI::BASIC::Program;

sub new {
    my ($class, %args) = @_;
    my $target = $args{target} || PETSGI::Target::PET40->new;
    my %self = (
        target => $target,
        nodes  => [],
    );
    return baptise \%self, $class, qw(target nodes);
}

sub title {
    my ($self, $text) = @_;
    push @{ $self->nodes }, { type => 'title', text => defined $text ? $text : '' };
    return $self;
}

sub text {
    my ($self, $text) = @_;
    push @{ $self->nodes }, { type => 'text', text => defined $text ? $text : '' };
    return $self;
}

sub blank {
    my ($self) = @_;
    push @{ $self->nodes }, { type => 'blank' };
    return $self;
}

sub menu {
    my ($self, @items) = @_;
    if (@items == 1 && ref($items[0]) eq 'ARRAY') {
        @items = @{ $items[0] };
    }
    my @normalized;
    for my $item (@items) {
        if (ref($item) eq 'HASH') {
            push @normalized, {
                label => defined $item->{label} ? $item->{label} : '',
                route => $item->{route},
            };
        }
        else {
            push @normalized, { label => defined $item ? $item : '', route => undef };
        }
    }
    push @{ $self->nodes }, { type => 'menu', items => \@normalized };
    return $self;
}

sub status {
    my ($self, $text) = @_;
    push @{ $self->nodes }, { type => 'status', text => defined $text ? $text : '' };
    return $self;
}

sub _fit {
    my ($self, $text) = @_;
    $text = '' unless defined $text;
    my $width = $self->target->columns;
    return substr($text, 0, $width);
}

sub _center {
    my ($self, $text) = @_;
    $text = $self->_fit($text);
    my $pad = int(($self->target->columns - length($text)) / 2);
    $pad = 0 if $pad < 0;
    return (' ' x $pad) . $text;
}

sub lines {
    my ($self) = @_;
    my @lines;
    my @status;

    for my $node (@{ $self->nodes }) {
        if ($node->{type} eq 'title') {
            push @lines, $self->_center($node->{text});
        }
        elsif ($node->{type} eq 'text') {
            push @lines, $self->_fit($node->{text});
        }
        elsif ($node->{type} eq 'blank') {
            push @lines, '';
        }
        elsif ($node->{type} eq 'menu') {
            my $n = 0;
            for my $item (@{ $node->{items} }) {
                $n++;
                push @lines, $self->_fit(sprintf('%2d. %s', $n, $item->{label}));
            }
        }
        elsif ($node->{type} eq 'status') {
            push @status, $self->_fit($node->{text});
        }
    }

    my $rows = $self->target->rows;
    if (@status) {
        my $room = $rows - scalar(@status);
        splice @lines, $room if @lines > $room;
        push @lines, ('') x ($room - @lines) if @lines < $room;
        push @lines, @status;
    }
    splice @lines, $rows if @lines > $rows;
    return @lines;
}

sub as_text {
    my ($self) = @_;
    return join("\n", $self->lines) . "\n";
}

sub basic_program {
    my ($self) = @_;
    my $p = PETSGI::BASIC::Program->new(start => $self->target->basic_start);
    my $line = 10;
    $p->clear_screen($line);
    $line += 10;
    my @lines = $self->lines;
    for my $i (0 .. $#lines) {
        my $stay = $i == $#lines ? 1 : 0;
        $p->print_line($line, $lines[$i], $stay);
        $line += 10;
    }
    $p->line($line, 'END');
    return $p;
}

sub prg {
    my ($self) = @_;
    return $self->basic_program->prg;
}

1;

__END__

=head1 NAME

PETSGI::UI::Screen - semantic 40-column PET screen builder

=head1 DESCRIPTION

This is PETSGI's initial UI intermediate representation. Application code
expresses PET-native concepts such as titles, text, menus, and status rows. The
0.01 renderer compiles the screen to tokenized PET BASIC. Native 6502 and hybrid
renderers may later consume the same semantic representation.

=head1 METHODS

=head2 title, text, blank, menu, status

Add semantic UI nodes and return the screen object for chaining.

=head2 lines

Returns the target-fitted screen rows.

=head2 basic_program

Returns a L<PETSGI::BASIC::Program> representation.

=head2 prg

Returns the executable PRG bytes.

=cut
