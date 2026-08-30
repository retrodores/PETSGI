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
      | routes, views, resources, actions, sessions
      v
PETSGI::Context + semantic UI/resource model
      |
      +-- VIEW         executable PRG application state
      +-- dynamic SEQ state polled by a resident PRG
      +-- ACTION       SEQ writes from the PET
      +-- RESOURCE     ordinary PRG / SEQ / D64
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

## Executable views

A PETSGI view is server-rendered application state whose representation is an
actual PET PRG. The server may query SQLite/session data, create a PET-native UI
tree, compile/tokenize/link it, materialize the result, and let PETdisk LOAD it.

Major application-state changes are expected to use executable PRGs. Smaller
updates can use dynamic SEQ resources while the current PRG remains resident:

```text
HOME.PRG              server-rendered application state
   |
   +-- STATE.SEQ      dynamic state / poll
   +-- CHAT.SEQ       dynamic state / poll
   +-- POST.SEQ       action / submission
   +-- BOARD.PRG      next executable view
```

This deliberately resembles a full-stack/reactive application model, but the
PET remains the design center and the response can itself be executable code.

## Context

`PETSGI::Context` is the application-facing boundary. It carries the normalized
request, target, resource, application, optional session store/token, and a UI
builder. Application code therefore does not need to know whether the request
arrived through CGI, PSGI, PETdisk, or a future transport.

## UI intermediate representation

`PETSGI::UI::Screen` is the initial semantic UI tree. It currently supports a
small 40-column vocabulary (`title`, `text`, `blank`, `menu`, `status`) and a
BASIC renderer. It is intentionally more semantic than screen-address PEEK/POKE
code.

Future work should add a local-effects ABI and native/hybrid renderer for such
operations as:

- highlighted/reverse-video keyboard menus
- input fields and forms
- scrollable regions
- dialogs and status bars
- navigation / refresh
- SEQ dynamic reads and write actions
- timers/polling suitable for chat and turn-based games

A template language should produce this same intermediate representation. The UI
tree, not template syntax, is the stable application abstraction.

## Why materialization is required under CGI

PETdisk obtains a resource in separate HTTP requests:

1. ask for its length;
2. request byte ranges, commonly 512 bytes at a time.

With CGI those requests execute separate Perl processes. A dynamic resource must
therefore be frozen somewhere outside process memory. `PETSGI::Materializer::File`
provides the initial short-lived, filesystem-backed implementation.

## Actions and the missing commit event

Stock PETdisk sends first, append, and block-update PUTs, but no final close or
commit request. PETSGI must not pretend otherwise. `action()` callbacks therefore
operate on individual blocks. A future application protocol may provide explicit
framing or commit records for multi-block transactional submissions.

## Sessions

PETdisk is not a browser and PETSGI does not assume HTTP cookies. Sessions are an
application-layer concept. The initial SQLite store supports a claimed username
and a compact token. This is identity, not strong authentication.

`session_resolver` belongs at the application/transport boundary so a future
transport may carry tokens differently without changing application callbacks.

## Future machines

The semantic application/UI layer should not knowingly depend on PETdisk. A
future target or transport could be implemented for systems such as a C64-class
machine, C64 OS, or Commander X16. These are architectural possibilities only;
they are not supported targets and must not reduce the quality of the PET UX.
