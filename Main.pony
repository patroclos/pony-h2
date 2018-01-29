use "files"
use "net"
use "ssl"

actor Main
  new create(env: Env) =>
    try
      let auth = env.root as AmbientAuth
      let cert = FilePath(auth, "./certs/cert.pem")?
      let key = FilePath(auth, "./certs/key.pem")?
      let ssl = recover val _get_sslctx(cert, key)? end
      TCPListener(auth, recover ServerListenNotify(env.out, ssl) end, "", "8080")
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