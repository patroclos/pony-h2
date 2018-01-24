use "net"
use "ssl"
use "files"
use "crypto"
use "buffered"


actor Main
  new create(env: Env) =>
    try
      let auth = env.root as AmbientAuth
      TCPListener(auth, recover ServerListenNotify(env.out, recover get_sslctx(env.root as AmbientAuth)? end) end, "", "8080")
      env.out.print("Server running on :8080")
    else
      env.out.print("Error setting up server")
    end
  
  fun get_sslctx(auth: AmbientAuth): SSLContext? =>
    let ctx = recover iso SSLContext end
    ctx.set_authority(FilePath(auth, "./certs/cert.pem")?)?
    ctx.set_cert(
      FilePath(auth, "./certs/cert.pem")?,
      FilePath(auth, "./certs/key.pem")?)?
    ctx.set_client_verify(false)
    ctx.set_server_verify(false)
    ctx.set_alpn_protos(recover iso ["h2"; "html/1.1"; "html/1.0"; "html"] end)
    consume ctx


class ServerListenNotify is TCPListenNotify
  let out: OutStream
  let sslctx: SSLContext
  new create(os: OutStream, sslctx': SSLContext) =>
    out = os
    sslctx = sslctx'

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^? =>
    try
      let ssl = sslctx.server()?
      recover SSLConnection(recover ServerSession(out) end, consume ssl) end
    else
      error
    end
  
  fun ref not_listening(listen: TCPListener ref) =>
    None

primitive HTTP
primitive H2
type HTTPMode is (HTTP|H2)

class ServerSession is TCPConnectionNotify
  let out: OutStream
  let reader: Reader

  // eg. first 24 bits prefix + settings etc
  var frameHeadOffset: (USize | None) = 24
  var http_mode:HTTPMode = H2

  new create(os: OutStream) =>
    os.print("[ NEW SESSION ]")
    out = os
    reader = Reader

  fun ref accepted(con: TCPConnection ref) =>
    None
  
  fun ref connect_failed(con: TCPConnection ref) =>
    None
  
  fun ref received(con: TCPConnection ref, data: Array[U8] iso, times: USize):Bool =>
    let arr: Array[U8] val = consume data

    out.print("GOT: " + String.from_array(arr))
    // append to local buffer
    reader.append(arr)

    match http_mode
    | H2 => try_handle_frame(con)
    | HTTP => try_upgrade()
    end

    true
  
  fun ref try_upgrade() =>
    let preface = "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"
    try
      error
    end
  
  fun ref try_handle_frame(con: TCPConnection ref) =>
    if has_frameheader() then
      match get_frameheader()
      | let header: FrameHeader val =>
          out.print("\n--- BEGIN FRAME HEADER ---")
          out.print("Length: " + header.length.string())
          out.print("FrameType: " + FrameTypes.name(header.frametype))
          out.print("Flags: " + header.flags.string())
          out.print("Stream ID: " + header.stream_identifier.string())
          out.print("--- END FRAME HEADER ---\n")

          try
            let payload: Array[U8] val = reader.block(header.length)?
            let payload_string = String.from_array(payload)
            frameHeadOffset = 0
            out.print("Payload: \n" + ToHexString(payload))
            out.print("Payload: \n" + payload_string + "\n")
          end

          match header.frametype
          | Settings => None
          | WindowUpdate => None
          | Headers =>
            // TODO: send settings frame back befor doing data
            try
              let send_set = recover val FrameHeader.from_values(0, Settings, 0, 0).to_bytes()? end
              out.print(ToHexString(send_set))
              con.write(send_set)

              let send_buf= recover iso FrameHeader.from_values(1, Headers, 4, header.stream_identifier).to_bytes()? end
              send_buf.push(Headers.status_200())

              let data_content_str = """
                <html><head><title>Hello, HTML2</title></head><body><h1>HELLO WORLD!</h1><p><em>which is h2</em></p></body></html>
              """

              let data_buf= recover iso FrameHeader.from_values(data_content_str.size(),Data,1,1).to_bytes()? end
              data_buf.append(data_content_str)

              send_buf.append(consume data_buf)

              let final_buf = consume val send_buf
              out.print("Sending: " + ToHexString(final_buf))
              con.write(final_buf)
            end
          end

          try_handle_frame(con)
      end
    end

  
  fun box has_frameheader(): Bool =>
    match frameHeadOffset
    | None => false
    | let offset: USize box =>
      let bufSize = reader.size()
      bufSize >= (offset + 9)
    end
  
  fun ref get_frameheader(): (FrameHeader val | None) =>
    try
      match frameHeadOffset
      | let offset: USize =>
        reader.skip(offset)?
        let bytes = reader.block(9)?
        frameHeadOffset = None
        recover FrameHeader(consume bytes)? end 
      end
    end