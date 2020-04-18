# pony-h2: A pony-based h2 server

*everything subject to change*

## Running the example
compile (openssl 1.1.x required for alpn)
`stable fetch && stable env ponyc -Dopenssl_1.1.x`

executing main will open a static server on port 8081 serving the ./public directory and using the selfsigned "localhost" certificate in ./certs

## Getting started

- Create a class implementing the RequestHandler interface
```pony
interface val RequestHandler
  fun on_request(req: Request val, res: Response trn): (Response val, Status)
```

- Create a `ServerListenerNotify` instance
`new create(out: OutStream, sslctx: SSLContext, request_handler: RequestHandler val)`

- Create a `TCPListener` and pass the `ServerListenerNotify` as notify

### Example static directory server

This program will build an SSLContext from certs/cert.pem and certs/key.pem,
bind to port 8080 and serve files from that directory

```pony
use "files"
use "net"
use "ssl"

actor Main
  new create(env: Env) =>
    try
      let auth = env.root as AmbientAuth

      let serve_dir = FilePath(auth, "./public", recover val FileCaps .> all() end)?
      let handler = recover val StaticRequestHandler(serve_dir) end

      let cert = FilePath(auth, "./certs/cert.pem")?
      let key = FilePath(auth, "./certs/key.pem")?
      let ssl = recover val _get_sslctx(cert, key)? end
      TCPListener(auth, recover ServerListenNotify(env.out, ssl, handler) end, "", "8080")
    else
      env.out.print("Failed to set up the server")
    end
  
  fun _get_sslctx(cert: FilePath, key: FilePath): SSLContext iso^? =>
    let ctx = recover iso SSLContext end
    ctx.set_authority(cert)?
    ctx.set_cert(cert, key)?
    ctx.set_client_verify(false)
    ctx.set_server_verify(false)
    ctx.set_alpn_protos(recover iso ["h2"] end)
    consume ctx

class val StaticRequestHandler
  let _servedir: FilePath

  new create(servedir: FilePath) =>
    _servedir = servedir
  
  fun on_request(req: Request val, res: Response trn): (Response val, Status) =>
    let status_code: Status = try
      let rpath = recover val String .> append(req.header(":path") as String) .> shift()? end
      let path = FilePath(_servedir, if rpath.size() == 0 then "index.html" else rpath end)?

      let file = OpenFile(path) as File

      let body: Array[U8] trn = recover trn Array[U8] end

      while file.errno() is FileOK do
        body.append(file.read(1024))
      end

      res.body = consume val body
      200
    else 404
    end

    (consume res, status_code)
```

## What works

- Header decoding

## What doesn't

- Literal header encoding