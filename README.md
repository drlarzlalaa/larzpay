# LarzPay

A money-native HTTP web framework for [Larzscript](https://larzos.com/larzos-linux/),
LarzOS's own language. Routes can be gated behind real payment using
Larzscript's own `wallet`/`pay ... from ... to ...` statements - not a
bolted-on third-party billing SDK.

```larzscript
import "app" as app
import "pay" as paymod
import "customer" as customer

let a = app.new()
wallet shop
let ledger = paymod.new(shop)

app.use(a, customer.middleware("app-secret"))
app.get(a, "/", fn(req) { return "hello" })
app.static(a, "/static", "./public")

paymod.pay_route(a, "GET", "/article/<int:id>", ledger, $0.10, fn(req) {
  return "article #" + str(req["params"]["id"])
})

app.run(a, 8080)
```

## What's actually in the box

- **`lib/httpmsg.lz`** - the real gap this project fills: Larzscript's
  `tcp` package gives you a working TCP server, but nothing to turn raw
  request bytes into a structured request or a response dict back into
  wire bytes. This does that (method/path/query/headers/body in,
  status/headers/body out).
- **`lib/app.lz`** - routing (built on the `router` package, not
  reimplemented), an ordered `fn(req, next)` middleware chain, and
  static file serving with a real path-traversal boundary (see
  Limitations - it's tested against both a literal `..` and a
  percent-encoded `%2e%2e`).
- **`lib/pay.lz`** - `pay_route()` (charge every request) and
  `access_route()` (charge once, grant time-limited access) - the
  money-native paywall primitive. Read the big comment at the top of
  this file before you use it; it explains a real language bug it
  works around (see below).
- **`lib/customer.lz`** - identifies a caller across requests with a
  signed session cookie (the `session` package), so a wallet persists
  across a curl `-b`/`-c` jar or a browser tab.

## Quickstart

```sh
larzscript examples/demo.lz    # LARZSCRIPT_PATH=./lib if running outside the repo root
```

Then, in another terminal (real output from an actual run against this repo):

```
$ curl -s -c /tmp/cj -b /tmp/cj http://127.0.0.1:8080/
LarzPay demo - see README for the curl walkthrough

$ curl -s -c /tmp/cj -b /tmp/cj http://127.0.0.1:8080/article/1
Payment Required: $0.10 needed. Fund your wallet (see README) and retry.

$ curl -s -c /tmp/cj -b /tmp/cj -X POST http://127.0.0.1:8080/fund
funded. balance: $10.00

$ curl -s -c /tmp/cj -b /tmp/cj http://127.0.0.1:8080/article/1
article #1: the price of a cup of coffee, priced in Larzscript.

$ curl -s -c /tmp/cj -b /tmp/cj http://127.0.0.1:8080/pro
welcome to the pro section - this access lasts 3600s from first charge

$ curl -s -c /tmp/cj -b /tmp/cj http://127.0.0.1:8080/pro
welcome to the pro section - this access lasts 3600s from first charge
```

(That last request is *not* re-charged - `access_route()` grants 3600s
of access on the first successful charge.)

## A real language bug this project works around

Larzscript has native `paywall`/`subscribe`/`... has ...` statements
that look purpose-built for exactly this project. They are **not used
here**. Verified this session, `larzscript` native 1.42.1:

```larzscript
wallet shop
paywall pro = $9.00 / month to shop

fn make_wallet(start) { wallet w = start; return w }
let alice = make_wallet($20.00)
let bob = make_wallet($20.00)

subscribe alice to pro
print("bob has pro:", bob has pro)   # prints true - bob never subscribed
```

Subscription state is tracked by the wallet's *declared local variable
name* ("w" in both cases above), not the runtime object's identity - so
any factory function that mints more than one wallet (exactly what a
web app does, once per customer) leaks access between unrelated
customers. Filed upstream:
[larz-scripter/larzscript#37](https://github.com/larz-scripter/larzscript/issues/37).

`lib/pay.lz` works around it by using plain `wallet`/`pay ... from ...
to ...` (verified independent per wallet object - two dynamically
created wallets keep separate, correct balances) for the actual money
movement, and tracking *access grants* in an ordinary Larzscript dict
keyed by customer id. `tests/customer_isolation.sh` is a regression
test for exactly this scenario, run against LarzPay's real HTTP
handlers, not the bug in isolation.

Also worth knowing: `pay`/`subscribe`/`require ... has ...` only accept
a bare identifier as their wallet operand - `pay $1 from customers["x"]
to shop` is a `SyntaxError`. Alias to a local first: `let w =
customers["x"]` then `pay $1 from w to shop` (this works, and is what
`lib/pay.lz` does internally).

## Limitations (honest, not hidden)

- **One connection at a time.** `tcp.serve()` is a real, working
  server, but Larzscript is a single-threaded interpreter with no
  concurrency primitive - it answers one request, then the next. Fine
  for a demo or an internal tool, not production traffic.
- **In-memory ledger.** Customer wallets and access grants live in a
  plain dict for the life of the process - restart the server and
  every balance/grant is gone. A real deployment would persist the
  ledger (e.g. via the `fs`/`json` packages) - out of scope for v1.
- **No chunked transfer-encoding, no HTTP/2, one `tcp.read()` per
  connection.** Fine for a curl-sized request/response over localhost;
  not a spec-complete HTTP/1.1 implementation.
- **`template` has no nesting** (a loop inside a loop, or a conditional
  inside a loop) - a deliberately small, single-pass engine. LarzPay
  doesn't currently ship a template example because of this; use it
  directly per its own docstring for anything beyond flat substitution.
- **A path matched under the wrong HTTP method returns 404, not 405.**
  The `router` package matches on path segments only, with no concept
  of method - LarzPay folds the method into the pattern as a leading
  segment rather than forking `router`, so "right path, wrong method"
  looks identical to "no such path."
- **Static path traversal defense is a strict reject, not a
  normalizer.** Any `..` segment in the decoded path is refused
  outright (403) rather than resolved - simpler and safe by
  construction, at the cost of also rejecting a few odd-but-legitimate
  encoded filenames.
- **The money type is `float`-backed**, same as every native Larzscript
  `$X.XX` value - fine for demo/small amounts, not a bignum ledger.

## Tests

```sh
sh tests/run_tests.sh
```

Each `tests/*.sh` starts its own `examples/demo.lz` instance on its own
port with a private cookie jar, drives it with real `curl` requests
(and one raw-socket request for the percent-encoded traversal case,
which curl itself would otherwise normalize away before it ever hit
the wire), and is torn down with a trap even on failure. `Set-Cookie`
values are redacted before diffing (a fresh uuid + HMAC signature every
run) - everything else in the `.expected` files is the framework's
real output.

## Third-party packages

See [THIRD_PARTY.md](THIRD_PARTY.md) - LarzPay is built on several
packages from `larz-scripter/larzscript-packages` (routing, sessions,
templating, MIME lookup, the TCP server itself); `lib/httpmsg.lz`,
`lib/app.lz`, `lib/pay.lz`, and `lib/customer.lz` are original to this
project.

## License

MIT - see [LICENSE](LICENSE).
