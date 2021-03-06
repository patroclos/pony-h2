use "files"
use "net"
use "net_ssl"

actor Main
  new create(env: Env) =>
    try
      let auth = env.root as AmbientAuth

      let serve_dir = FilePath(auth, "./public", recover val FileCaps .> all() end)?
      let handler = recover val StaticRequestHandler(serve_dir) end

      let cert = FilePath(auth, "./certs/cert.pem")?
      let key = FilePath(auth, "./certs/key.pem")?
      let ssl = recover val _get_sslctx(cert, key)? end
      TCPListener(auth, recover ServerListenNotify(env.out, ssl, handler) end, "", "8081")
    else
      env.out.print("Failed to set up the server")
    end
  
  fun _get_sslctx(cert: FilePath, key: FilePath): SSLContext iso^? =>
    let ctx = recover iso SSLContext end
    ctx.set_authority(cert)?
    ctx.set_cert(cert, key)?
    ctx.set_client_verify(false)
    ctx.set_server_verify(false)
    ctx.alpn_set_resolver(ALPNStandardProtocolResolver(recover val ["h2"] end))
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