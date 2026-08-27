# smi-serve-files security V&V

Scope: static file serving from one `www` directory, loopback bind, behind nginx/haproxy.
Test target: `src/main/elixir/server/lib/smi-serve-files.exs` and `src/main/sh/server/bin/smi-serve-files`.

How to run: start the server against a throwaway `www` containing a dotfile, a symlink, a deep
directory tree and a file with a space; probe with `curl -s --path-as-is`. Every bullet is one
request or one shell invocation with an expected result. `[ ]` = not yet tested.

## V&V

### Path traversal
- [x] `/../workingdir/x` → 404
- [x] `/a/../b` → 404
- [x] `/%2e%2e/x` → 404
- [x] `/assets/../../workingdir/x` → 404
- [x] `/a%2fb` (encoded slash) → 404
- [x] `/a%5cb` (encoded backslash) → 404
- [x] `/a%3ab` (colon) → 404
- [ ] `/..%2f..%2fetc/passwd` → 404
- [ ] `/%252e%252e/x` (double encoded) → 404 or index, never a file outside www
- [ ] `/a/./b` → 404
- [ ] overlong UTF-8 `%c0%ae%c0%ae/` → 404
- [ ] Unicode dot lookalikes `/․․/` → 404 or index, never traversal

### Hidden and sensitive files
- [x] `/.env` → 404
- [x] `/%2eenv` → 404
- [x] `/assets/.hidden` → 404
- [ ] `/.git/HEAD` → 404
- [ ] `/.htaccess` → 404
- [ ] `/.well-known/x` → 404 (confirm this is wanted; ACME challenges are the proxy's job)
- [ ] `/index.html.bak`, `/main.js.map` → 200 (served, by design: everything in www is public; the deploy must not put them there)

### File system objects
- [x] symlink inside www → server refuses to start
- [x] FIFO inside www → server refuses to start
- [ ] hard link inside www to a file outside → served (known, only root can create; decide if `-links +1` refusal is wanted)
- [ ] directory request `/assets/` → index.html, never a listing
- [ ] directory without index `/subdir/` → index.html, never a listing
- [ ] file with no read permission for `microservice` → 404 or 500, never a hang
- [ ] file replaced while server running → new content served, no crash
- [ ] file deleted while server running → index.html fallback, no crash

### Control and non-printable characters
- [x] `/a%01b` → 404
- [x] `/a%00b` → 400 or 404
- [x] `/a%7fb` → 404
- [ ] `/a%0d%0ab` (CRLF) → 404
- [ ] `/a%09b` (tab) → 404
- [ ] `/a%e2%80%8bb` (zero width space) → 404
- [x] `/a%20b.txt` (space, legit) → 200

### Size and depth limits
- [x] path > 2048 bytes → 404
- [x] depth > 16 segments → 404
- [ ] request line > 10000 bytes → 4xx, connection closed
- [ ] header > 10000 bytes → 4xx
- [ ] more than 50 headers → 4xx
- [ ] query string > 8 KB → still served or 4xx, never crash
- [ ] 1000 concurrent keep-alive connections → no crash, memory bounded
- [ ] slowloris: open connection, send one byte per 10 s → closed by read timeout

### HTTP methods
- [x] GET → 200
- [x] HEAD → 200, zero body, logged as HEAD
- [x] HEAD on SPA route → 200
- [x] POST, PUT, DELETE, PATCH, OPTIONS, TRACE → 405 with `Allow: GET, HEAD`
- [ ] lowercase `get` → 405 or 400
- [ ] unknown method `FOO` → 405
- [ ] POST with 10 MB body → 405, body drained, connection not stuck
- [ ] `Expect: 100-continue` with POST → 405, no 100 sent

### Protocol surface
- [x] HTTP/2 prior knowledge or h2c upgrade → stays HTTP/1.1
- [x] WebSocket upgrade → 200 normal response, never 101
- [ ] HTTP/1.0 request → served
- [ ] HTTP/0.9 request → 400
- [ ] request without Host header → 400 or served, never crash
- [ ] pipelined requests → all answered in order
- [ ] `Transfer-Encoding: chunked` on GET → served or 400
- [ ] `Content-Length` and `Transfer-Encoding` both set (smuggling) → 400
- [ ] `Range: bytes=0-10` → 200 full or 206, never 500
- [ ] `Range: bytes=999999999-` → 200 or 416, never 500
- [ ] `If-None-Match` with the served etag → 304
- [ ] `Accept-Encoding: gzip` → identity served, never a precompressed file from disk unless intended

### Response headers
- [x] `x-content-type-options: nosniff` on every response
- [x] no `server` header
- [ ] no `x-powered-by`
- [ ] correct `content-type` for html, js, css, svg, json, woff2, wasm, unknown extension
- [ ] `index.html` fallback has `text/html; charset=utf-8`
- [ ] 404 and 405 bodies are plain text, no path echoed back
- [ ] 500 body is empty, no stack trace

### Logging
- [x] every request produces one combined-format line on stdout
- [x] `X-Forwarded-For: a, b` → logged client is `b` (last, proxy appended)
- [x] `"` in user-agent → replaced by `?`
- [x] control characters in user-agent → replaced by `?`
- [x] `"` in referer → replaced by `?`
- [x] bytes column is the real body size, 0 for HEAD
- [ ] `X-Forwarded-For` absent → 127.0.0.1
- [ ] `X-Forwarded-For` empty value → 127.0.0.1 or `?`, never crash
- [ ] `X-Forwarded-For` with 100 entries → last, no crash
- [ ] request rejected at parse level (400) → appears in log or documented as proxy's job
- [ ] request path with `%0a` → logged on one line
- [ ] 10000 requests → no log line lost, no memory growth
- [ ] log survives stdout being a pipe that blocks briefly

### Shell script, arguments
- [x] name with space → invalid name
- [x] name with `*` → invalid name
- [x] name with `$HOME` → invalid name
- [x] name `-rf` → invalid name
- [x] name `../x` → invalid name
- [x] name `.h` → invalid name
- [x] port `abc`, `0`, `70000` → invalid port
- [ ] name of 300 characters → invalid or works, never truncates into another app's dir
- [ ] empty string argument `""` → usage
- [ ] port `080` → treated as 80 or rejected, decide
- [ ] port < 1024 → bind fails cleanly as microservice, clear error

### Shell script, privileges and file system
- [x] not root → refuses
- [x] `microservice` user missing → refuses
- [x] `www` missing → refuses
- [ ] after start: `www` is root:root, dirs 755, files 644
- [ ] after start: `workingdir` is microservice:microservice 700
- [ ] server process runs as `microservice`, not root (`ps -o user`)
- [ ] server cwd is `workingdir` (`ls -l /proc/PID/cwd`)
- [ ] server cannot write into `www` (verify from inside: `touch www/x` fails)
- [ ] server cannot read `workingdir` of another app
- [ ] server cannot read other organizations' directories
- [ ] `HOME` of the process is `workingdir`
- [ ] environment of the process has no secrets inherited from root (`cat /proc/PID/environ`)
- [ ] `PATH` of the process starts with `/opt/erlang/bin:/opt/elixir/bin`
- [ ] runs on OTP from `/opt/erlang`, not the distribution one
- [ ] `www` owned by another user before start → becomes root:root, nothing outside www touched
- [ ] `www` is itself a symlink → decide: refuse

### Dependency cache
- [ ] `workingdir/mix-install` is writable by microservice → known weakness, persistence after compromise
- [ ] first start without network → clear error, not a hang
- [ ] second start without network → works from cache
- [ ] tampered `.beam` in cache → currently loaded; test to confirm, then decide on root-owned cache

### Bind and reachability
- [x] listens on 127.0.0.1 only (`ss -ltnp`)
- [ ] not reachable from another host on the LAN
- [ ] inside Docker with proxy in another container → unreachable; needs bind-address option
- [ ] two instances on the same port → second fails with clear `eaddrinuse`
- [ ] IPv6 `::1` → not listening (decide if wanted)

### Behind the proxy
- [ ] proxy sets `X-Forwarded-For` by appending → verify with real nginx `proxy_add_x_forwarded_for`
- [ ] proxy strips client-sent `X-Forwarded-For` or appends → document required config
- [ ] proxy adds `X-Frame-Options`, CSP, HSTS → confirm these are the proxy's, not missing
- [ ] proxy limits request body → confirm, since server accepts any body size before 405
- [ ] proxy timeout shorter than Bandit read timeout → confirm

### Denial of service
- [ ] 10000 requests/s for `/index.html` → serves, bounded CPU
- [ ] 10000 requests/s for a 404 path → serves, bounded CPU
- [ ] 10000 requests/s for a 2048-byte path → guard rejects cheaply, no file system access
- [ ] 100 MB file in www → served with send_file, memory flat
- [ ] 10000 files in one directory → lookup still fast

### Regression on every change
- [ ] all `[x]` above re-run
- [ ] `sh -n` on the shell script
- [ ] man page renders without warnings
- [ ] `hello-server` example page serves all four files
- [ ] log line format unchanged (parsers depend on it)
