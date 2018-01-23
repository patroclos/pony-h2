use "net"
use "crypto"
use "buffered"

actor Main
  new create(env: Env) =>

    try
      let auth = env.root as AmbientAuth
      TCPListener(auth, recover SessionTCPListener(env.out) end, "", "8080")
      env.out.print("Server running on :8080")
    else
      env.out.print("Error setting up server")
    end

class SessionTCPListener is TCPListenNotify
  let out: OutStream
  new create(os: OutStream) =>
    out = os

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    recover SessionConnectionHandler(out) end
  
  fun ref not_listening(listen: TCPListener ref) =>
    None

class SessionConnectionHandler is TCPConnectionNotify
  let out: OutStream
  let buf: Array[U8]
  let reader: Reader

  // eg. first 24 bits prefix + settings etc
  let initialized: Bool = false
  var frameHeadOffset: (USize | None) = 24

  new create(os: OutStream) =>
    out = os
    buf = Array[U8]
    reader = Reader

  fun ref accepted(con: TCPConnection ref) =>
    out.print("accept")
    con.write("Hello")
  
  fun ref connect_failed(con: TCPConnection ref) =>
    None
  
  fun ref received(con: TCPConnection ref, data: Array[U8] iso, times: USize):Bool =>
    let arr: Array[U8] val = consume data

    // append to local buffer
    buf.append(arr)
    reader.append(arr)

    try_handle_frame(con)

    let str = String.from_array(arr)
    let num_recv = arr.size()

    out.print("Got " + num_recv.string() + " bytes:\n" + ToHexString(arr) + "\n")
    //out.print(str)

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


          try
            let payload: Array[U8] val = reader.block(header.length)?
            let payload_string = String.from_array(payload)
            frameHeadOffset = 0
            out.print("Payload: \n" + ToHexString(payload))
            out.print("Payload: \n" + payload_string + "\n")
          end

          match header.frametype
          | Settings =>
            out.print("Handeling Settings Frame")
          | WindowUpdate =>
            out.print("Handeling WindowUpdate Frame")
          | Headers =>
            // TODO: send settings frame back befor doing data
            try
              let send_set = recover iso FrameHeader.from_values(0, Settings, 1, 0).to_bytes()? end
              con.write(consume val send_set)

/*
              let send_buf = recover iso FrameHeader.from_values(10, Data, 1, 1).to_bytes()? end
              send_buf.append("1234567890")
              con.write(consume val send_buf)
              */
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