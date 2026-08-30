# Stock PETdisk MAX protocol boundary used by PETSGI

PETSGI 0.x is bounded by the HTTP behavior already emitted by unmodified PETdisk
MAX firmware.

| PETdisk operation | HTTP form | PETSGI operation |
|---|---|---|
| directory page | `GET ?d=1&p=N` | `DIRECTORY` |
| file length | `GET ?file=NAME&l=1` | `STAT` |
| file/range read | `GET ?file=NAME&s=A&e=B` | `READ` |
| first write block | `PUT ?f=NAME&n=1&b64=1` | `CREATE` |
| later write block | `PUT ?f=NAME&b64=1` | `APPEND` |
| random block update | `PUT ?f=NAME&u=1&s=A&e=B&b64=1` | `UPDATE` |
| clock pseudo-file | ordinary `file=TIME` requests | resource `TIME` |

Writes are base64 encoded by PETdisk's HTTP layer. The normal network read/write
buffer is 512 bytes.

## Important constraints

### No HTTP close/commit request

Closing a PET file does not generate a final network request. For an ordinary
file this is harmless: each PUT can be persisted immediately. For an application
submission larger than one write buffer, however, the server cannot infer from
the final APPEND alone that the PET has closed the logical request.

PETSGI applications should therefore initially use one of these patterns:

- keep command/form submissions within one PETdisk write block where practical;
- stage CREATE/APPEND data and explicitly commit it through a later application
  transition/resource;
- design a higher-level application payload with an explicit end marker.

This is an application-protocol concern, not something PETSGI should pretend the
stock firmware supplies.

### Network directories are flat

The current NetworkDataSource accepts `openDirectory()` but does not transmit the
directory name to the server and does not report directory entry type. Genuine
remote directory traversal therefore cannot be added purely server-side.

PETSGI may provide categories through dynamic PRGs, virtual resources, and D64
collections, but it must not claim these are firmware-level network directories.

### Dynamic resources must remain stable across range requests

The initial STAT and subsequent READs may happen in different CGI processes.
PETSGI materializes a dynamic response before returning its length and serves the
following ranges from that frozen representation.

### Filenames are an application namespace

PETSGI may treat a name such as `MENU.PRG`, `NEWS.SEQ`, or `MSG0042.PRG` as a
route rather than a Unix file. Keep application-visible names conservative and
short: the PET firmware maintains small fixed filename buffers and PET-native UX
benefits from concise names anyway.

### Status codes are secondary to payload compatibility

The historical PHP endpoint is loose about HTTP errors, while PETdisk is mainly
interested in the payload. PETSGI uses sensible status codes but keeps successful
wire payloads compatible with what PETdisk expects.
