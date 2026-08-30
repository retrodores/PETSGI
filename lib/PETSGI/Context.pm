package PETSGI::Context;

use strict;
use warnings;
use Util::H2O::More qw(baptise);

sub new {
    my ($class, %args) = @_;
    my %self = (
        request       => $args{request},
        application   => $args{application},
        resource      => $args{resource},
        target        => $args{target},
        session_store => $args{session_store},
        session_token => $args{session_token},
        stash         => $args{stash} || {},
    );
    return baptise \%self, $class,
        qw(request application resource target session_store session_token stash);
}

sub ui {
    my ($self) = @_;
    require PETSGI::UI::Screen;
    return PETSGI::UI::Screen->new(target => $self->target);
}

sub state {
    my ($self, $name, @set) = @_;
    die "no session store in this application\n" unless $self->session_store;
    die "no session token for this request\n" unless defined $self->session_token && length $self->session_token;
    return @set
        ? $self->session_store->set($self->session_token, $name, $set[0])
        : $self->session_store->get($self->session_token, $name);
}

sub username {
    my ($self) = @_;
    return unless $self->session_store;
    return unless defined $self->session_token && length $self->session_token;
    return $self->session_store->username($self->session_token);
}

sub compile_view {
    my ($self, $view) = @_;
    return '' unless defined $view;
    return $view unless ref $view;
    return $view->prg if $view->can('prg');
    die "view object cannot be compiled to a PRG\n";
}

1;

__END__

=head1 NAME

PETSGI::Context - application-facing PETSGI request context

=head1 DESCRIPTION

A context hides CGI and PETdisk transport details from application callbacks. It
provides access to the normalized request, application, target, current resource,
optional session state, and the semantic UI builder.

=head1 METHODS

=head2 ui

Returns a new L<PETSGI::UI::Screen> for the current target.

=head2 state

Reads or writes one application-session state value when a session store and
resolved token are available.

=head2 username

Returns the claimed session identity when available.

=cut
