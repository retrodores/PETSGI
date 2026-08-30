package PETSGI::Session::SQLite;

use strict;
use warnings;
use Util::H2O::More qw(baptise);

sub new {
    my ($class, %args) = @_;
    my $path = $args{path} || die "SQLite path required\n";
    require DBI;
    require DBD::SQLite;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$path", '', '', {
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
    });
    $dbh->do('PRAGMA busy_timeout = 5000');
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS petsgi_session (
            token TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            created INTEGER NOT NULL,
            last_seen INTEGER NOT NULL
        )
    });
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS petsgi_state (
            token TEXT NOT NULL,
            name TEXT NOT NULL,
            value TEXT,
            PRIMARY KEY (token, name)
        )
    });
    my %self = (path => $path, dbh => $dbh);
    return baptise \%self, $class, qw(path dbh);
}

sub identify {
    my ($self, $username) = @_;
    die "username required\n" unless defined $username && length $username;
    $username =~ s/^\s+|\s+$//g;
    die "invalid username\n" unless $username =~ /^[A-Za-z0-9 _.-]{1,24}$/;
    my $token = join('', map { sprintf '%X', int(rand(16)) } 1 .. 12);
    my $now = time;
    $self->dbh->do(
        'INSERT INTO petsgi_session(token, username, created, last_seen) VALUES (?, ?, ?, ?)',
        undef, $token, uc($username), $now, $now,
    );
    return $token;
}

sub username {
    my ($self, $token) = @_;
    my ($username) = $self->dbh->selectrow_array(
        'SELECT username FROM petsgi_session WHERE token = ?', undef, $token,
    );
    if (defined $username) {
        $self->dbh->do('UPDATE petsgi_session SET last_seen = ? WHERE token = ?', undef, time, $token);
    }
    return $username;
}

sub set {
    my ($self, $token, $name, $value) = @_;
    $self->dbh->do(q{
        INSERT OR REPLACE INTO petsgi_state(token, name, value) VALUES (?, ?, ?)
    }, undef, $token, $name, $value);
    return $value;
}

sub get {
    my ($self, $token, $name) = @_;
    my ($value) = $self->dbh->selectrow_array(
        'SELECT value FROM petsgi_state WHERE token = ? AND name = ?', undef, $token, $name,
    );
    return $value;
}

1;
