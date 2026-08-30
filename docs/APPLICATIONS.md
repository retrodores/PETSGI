# Writing PETSGI applications

PETSGI provides a low-level `resource()` API and a higher-level semantic API for
full-stack applications.

## Executable view

```perl
$app->view(
    name => 'HOME.PRG',
    render => sub {
        my ($ctx) = @_;
        return $ctx->ui
            ->title('MY PET APP')
            ->blank
            ->text('SERVER STATE GOES HERE')
            ->menu(
                { label => 'FIRST ITEM', route => 'FIRST.PRG' },
                { label => 'SECOND ITEM', route => 'SECOND.PRG' },
            );
    },
);
```

The route metadata in menu nodes is retained in the semantic UI tree even though
the 0.01 BASIC renderer does not yet implement native navigation. A later
local-effects renderer can compile the same application description to PET-side
keyboard/menu behavior.

## Dynamic SEQ resource

A resident PRG may poll an ordinary dynamic SEQ resource when it needs fresh
data without replacing the current executable view. PETSGI deliberately does
not give this pattern a separate framework abstraction in 0.01.

```perl
$app->resource(
    name => 'STATE.SEQ',
    type => 'SEQ',
    read => sub {
        my ($req, $application, $resource) = @_;
        return current_state_as_seq();
    },
);
```

Use dynamic PRG views for major application/UX transitions and dynamic SEQ when
the current PRG can remain resident and merely needs updated data.

## Action

An action consumes PETdisk PUT data:

```perl
$app->action(
    name => 'POST.SEQ',
    write => sub {
        my ($ctx, $bytes, $operation) = @_;
        # CREATE is the first block; APPEND is a later block.
    },
);
```

There is no stock-firmware close/commit event. Keep a submission within one block
when practical, or define explicit application framing for larger transactions.

## Context and state

Callbacks receive a `PETSGI::Context`. If the application has a session store and
resolver, application code can use:

```perl
my $name = $ctx->username;
my $page = $ctx->state('page');
$ctx->state(page => 2);
```

This keeps session transport out of application logic.

## Templates

PETSGI does not yet freeze a template syntax. The intended architecture is:

```text
template ---------+
                   |
Perl UI builder ---+--> semantic UI tree --> PET target renderer --> PRG
                   |
components --------+
```

This allows a future PET-oriented declarative/template language without coupling
application semantics to a particular markup syntax.
