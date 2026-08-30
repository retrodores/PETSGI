# PETSGI architecture

## Design rule

PETSGI is **PET-first, not PET-locked**. Version 0.x supports and tests one
combination only:

- target: 40-column Commodore PET
- transport: unmodified PETdisk MAX network protocol
- initial server adapter: CGI via CGI::Tiny

The application layer must not receive CGI::Tiny objects or PETdisk HTTP query
parameters directly. Those are adapter/transport concerns.

## Layers

```text
PETSGI application
      |
      | routes, views, sessions, application state
      v
PETSGI resource/view model
      |
      +-- executable PRG response (primary UX direction)
      +-- SEQ stream/submission
      +-- D64 mounted storage/content
      +-- directory discovery
      |
      v
PETSGI normalized operations
      |
      | DIRECTORY STAT READ CREATE APPEND UPDATE
      v
PETSGI::Protocol::PETdisk
      |
      v
PETdisk MAX HTTP
```

The web-runtime direction is orthogonal:

```text
shared hosting                     future persistent host
Apache CGI                         reverse proxy / PSGI
    |                                      |
CGI::Tiny adapter                  future adapter
    |                                      |
    +-------------- PETSGI core -----------+
```

## Dynamic PRGs

PETSGI treats an application PRG as an executable response, not merely static
content. A route may query SQLite/session state, build a BASIC/6502/hybrid PET
program, materialize it, and let PETdisk LOAD it.

The planned UI layer will compile a PET-native component tree to a 40-column PET
runtime. Applications should describe effects such as menu, input, navigate,
submit, scroll, and stream rather than writing PEEK/POKE or PETdisk mechanics.

`PETSGI::BASIC::Program` in 0.01 is intentionally only a first executable-response
proof of concept.

## Why materialization is required under CGI

PETdisk obtains a resource in separate HTTP requests:

1. ask for its length;
2. request byte ranges, commonly 512 bytes at a time.

With CGI those requests execute separate Perl processes. A dynamic resource must
therefore be frozen somewhere outside process memory. `PETSGI::Materializer::File`
provides the initial short-lived, filesystem-backed implementation.

## Sessions

PETdisk is not a browser and PETSGI does not assume HTTP cookies. Sessions are an
application-layer concept. The initial SQLite store supports a claimed username
and a compact token. This is identity, not strong authentication.

Future applications may carry a token in a short PET resource name, a SEQ request
body, or another transport-specific mechanism.

## Future machines

The semantic application/UI layer should not knowingly depend on PETdisk. A
future target or transport could be implemented for systems such as a C64-class
machine, C64 OS, or Commander X16. These are architectural possibilities only;
they are not supported targets and must not reduce the quality of the PET UX.
