# PETSGI

**PETSGI (PET Server Gateway Interface)** is an experimental Perl application
framework for unmodified Commodore PET systems using PETdisk MAX.

The first supported target is deliberately narrow: a **40-column Commodore PET**
and the stock PETdisk MAX network protocol. PETSGI is *PET-first, not PET-locked*:
application semantics, target rendering, and transport are separated so future
third-party targets/transports do not have to weaken the PET implementation.

## The idea

PETdisk already turns Commodore disk operations into a small bidirectional HTTP
protocol. PETSGI normalizes that protocol into application operations:

| PETdisk request | PETSGI operation | Application meaning |
|---|---|---|
| `GET ?d=1&p=N` | `DIRECTORY` | discovery / launcher |
| `GET ?file=X&l=1` | `STAT` | materialize and size a response |
| `GET ?file=X&s=A&e=B` | `READ` | ranged response transport |
| `PUT ?f=X&n=1&b64=1` | `CREATE` | first write block |
| `PUT ?f=X&b64=1` | `APPEND` | subsequent write block |
| `PUT ?f=X&u=1&s=A&e=B&b64=1` | `UPDATE` | random-access update |

PRG is intended to become PETSGI's primary executable UX response; SEQ is useful
for streams/submissions and D64 for mounted storage and software collections.

## Shared-hosting baseline

`examples/petsgi.cgi` is a CGI::Tiny deployment which behaves like the original
`petdisk.php` for PRG/SEQ/D64, ranged reads, writes, and TIME, while adding safer
filename handling and cleaner implementation boundaries.

```text
10,example.com/cgi-bin/petsgi.cgi
```

Set `PETSGI_ROOT` to the directory to expose.

## Dynamic PRG proof of concept

`examples/dynamic-menu.cgi` adds a virtual `MENU.PRG`. The program is generated
on the server as tokenized PET BASIC and materialized to a short-lived filesystem
cache so PETdisk's separate size and range requests see one stable executable.

```basic
LOAD"MENU",10
RUN
```

The initial BASIC generator targets the PET BASIC program address at `$0401` and
only claims the 40-column PET target. It is intentionally a small foundation for
a later PET-native local-effects/UI runtime, not a complete BASIC compiler yet.

## Testing

`PETSGI::Test::PETdiskMax` mocks only the part of PETdisk MAX that PETSGI depends
on: directory pages, stat-before-read, 512-byte range reads, first/append PUTs,
block updates, and base64 write bodies. It deliberately does not emulate IEEE-488,
Wi-Fi, LEDs, or other firmware internals.

```sh
prove -lr t
```

GitHub Actions tests several Perl versions and runs Devel::Cover on the latest.
SQLite session tests run when DBI/DBD::SQLite are installed.

## Sessions and identity

`PETSGI::Session::SQLite` provides an intentionally modest first session model:
a user may claim a name and receive a compact PETSGI token. This is identity, not
strong authentication. The abstraction is designed so actual authentication can
be added later without changing application state APIs.

## Dependencies

The CGI adapter uses `CGI::Tiny`; PETSGI operation routing uses `Dispatch::Fu`;
small request/resource/context objects use `Util::H2O::More`. DBI and DBD::SQLite
are recommended for sessions rather than required for simple file service.

## Status

This is an initial 0.01 design/prototype. The next major work is the dynamic PRG
view layer: a declarative, PET-native template/component tree and a stable local
effects ABI which can render to BASIC, 6502, or a hybrid while remaining native
to the 40-column PET.
