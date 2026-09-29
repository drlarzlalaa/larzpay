# Third-party packages

LarzPay is built on several packages from
[larz-scripter/larzscript-packages](https://github.com/larz-scripter/larzscript-packages)
(same ecosystem/org as the language itself, MIT-compatible). They are not
vendored into this repo - CI and local development fetch them straight
from that repo's `master` branch into `~/.larzscript/lib` (see
`.github/workflows/test.yml`), the same convention every other
`larzscript-*`/`larz-*` project in this account uses. Nothing in this
list was written for LarzPay; LarzPay is the layer on top that turns
them into a web framework.

| Package | Used for |
| --- | --- |
| `router` | URL pattern matching (`<name>`, `<int:id>`) |
| `mime` | Content-Type lookup for static files |
| `url` | query-string and percent-encoding, used in request parsing and static path decoding |
| `tcp` | the real TCP server underneath `app.run()` |
| `session` | signed-cookie customer identity |
| `json`, `base64`, `crypto`, `uuid` | `session`'s own dependencies |
| `random` | `uuid`'s own dependency |

`lib/httpmsg.lz`, `lib/app.lz`, `lib/pay.lz`, and `lib/customer.lz` are
original to this project.
