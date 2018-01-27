use "net"
use "files"
use "crypto"
use "buffered"
use "collections"

use "ssl"
use "frames"


actor Main
  new create(env: Env) =>
    try
      let auth = env.root as AmbientAuth
      TCPListener(auth, recover ServerListenNotify(env.out, recover get_sslctx(env.root as AmbientAuth)? end) end, "", "8080")
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
    ctx.set_alpn_protos(recover iso ["h2"/*; "html/1.1"; "html/1.0"; "html"*/] end)
    consume ctx


class ServerListenNotify is TCPListenNotify
  let out: OutStream
  let sslctx: SSLContext
  new create(os: OutStream, sslctx': SSLContext) =>
    out = os
    sslctx = sslctx'

  fun ref listening(listener: TCPListener ref) =>
    out.print("Bound to " + NetAddressUtil.ip_port_str(listener.local_address()))

  fun ref not_listening(listen: TCPListener ref) =>
    out.print("Error binding to address")
    None

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^? =>
    let addr = listen.local_address().addr

    try
      let ssl = sslctx.server()?
      recover SSLConnection(recover ServerSession(out) end, consume ssl) end
    else
      out.print("Error setting up SSL listener")
      error
    end


class ServerSession is TCPConnectionNotify
  let out: OutStream
  let reader: Reader
  let dynamic_headers: List[(String,String)] = List[(String, String)]

  // eg. first 24 bits prefix + settings etc
  var frameHeadOffset: (USize | None) = 24

  new create(os: OutStream) =>
    out = os
    reader = Reader

  fun ref accepted(con: TCPConnection ref) =>
    out.print("Connection from " + NetAddressUtil.ip_port_str(con.remote_address()))
    None
  
  fun ref connect_failed(con: TCPConnection ref) =>
    out.print("Connection from " + NetAddressUtil.ip_port_str(con.remote_address()) + " failed!")
    None
  
  fun ref received(con: TCPConnection ref, data: Array[U8] iso, times: USize):Bool =>
    reader.append(consume data)
    try_handle_frame(con)
    true

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

          let payload: Array[U8] val = try reader.block(header.length)? else out.print("could not read payload"); return end
          let payload_string = String.from_array(payload)
          frameHeadOffset = 0

          match header.frametype
          | Settings => None
          | WindowUpdate => None
          | Headers =>
            let frame = HeadersFrame(header, dynamic_headers, out)
              .> parse_fields(payload)
            for (k,v) in frame.fields().values() do
              out.print("HEADER: " + k + " => " + v)
            end
            // TODO: send settings frame back befor doing data
            try
              let send_set = recover val FrameHeader.from_values(0, Settings, 0, 0).to_bytes()? end
              con.write(send_set)

              let send_buf= recover iso FrameHeader.from_values(1, Headers, 4, header.stream_identifier).to_bytes()? end
              match HeaderField.get_index(":status", U16(200), None)
              | let i:U8 =>
                send_buf.push(HeaderField.indexed(i))
              | None =>
                out.print("Error getting index for :status header!")
                send_buf.push(HeaderField.indexed(14))
              end

              let data_content_str = """
                <html><head><title>Hello, HTML2</title></head><body><h1>HELLO WORLD!</h1><p><em>which is h2</em></p></body></html>
              """

              let data_buf= recover iso FrameHeader.from_values(data_content_str.size(),Data,1,header.stream_identifier).to_bytes()? end
              data_buf.append(data_content_str)

              send_buf.append(consume data_buf)

              let final_buf = consume val send_buf
              con.write(final_buf)
            end
          else
            out.print("Error handling Headers frame")
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