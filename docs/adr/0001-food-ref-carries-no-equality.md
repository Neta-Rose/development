# FoodRef carries no value equality

A food hit's identity is a sealed `FoodRef` — catalog food, custom food, or
unsaved food — and none of the three cases defines `==`. Two refs to the same
catalog food are therefore not equal, only identical.

This is deliberate, and it will look like an oversight.

## Why

Nothing needs equality. The one caller that might — `foodExtrasProvider`, keyed
on the ref — is auto-dispose, so it dies with the detail screen and re-queries on
the next visit whether or not the key compares by value. Within a single screen
the ref instance is stable, so identity-keying already behaves correctly. Adding
`==` would buy a cache that nothing keeps.

Against that: the food staging machinery on the search screen is built on
`identical`, not `==`. `Batch.remove` and `Batch.replace` locate a staged item by
identity so that the same food staged twice is two independent rows, and
`mergePlate` returns fresh instances on every detection reply to match. Value
equality anywhere near that code is an invitation to "simplify" those comparisons
to `==`, at which point a detection reply silently rewrites the wrong staged row.
Equality on `FoodRef` would not break this on its own — `Batch` compares staged
items, never refs — but it puts the loaded gun on the table for no gain.

## If this is revisited

Adding `==` later is cheap and safe, and there are two honest reasons to:
keeping the extras query alive across visits, or a caller that rebuilds refs
every frame and thrashes the provider. Neither exists today. If you add it, leave
`Batch` and `mergePlate` alone — their use of `identical` is load-bearing and
documented where it lives.
