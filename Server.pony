use "net"
use "buffered"
use "collections"

use "ssl"
use "frames"

class ServerListenNotify is TCPListenNotify
  let out: OutStream
  let sslctx: SSLContext
  let _request_handler: RequestHandler val
  new create(os: OutStream, sslctx': SSLContext, request_handler: RequestHandler val) =>
    out = os
    sslctx = sslctx'
    _request_handler = request_handler

  fun ref listening(listener: TCPListener ref) =>
    out.print("Bound to " + NetAddressUtil.ip_port_str(listener.local_address()))

  fun ref not_listening(listen: TCPListener ref) =>
    out.print("Error binding to address")
    None

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^? =>
    let addr = listen.local_address().addr

    try
      let ssl = sslctx.server()?
      recover SSLConnection(recover ServerSession(out, _request_handler) end, consume ssl) end
    else
      out.print("Error setting up SSL listener")
      error
    end


class ServerSession is TCPConnectionNotify
  let out: OutStream
  let _request_handler: RequestHandler val
  let _frame_stream_parser: FrameStreamParser = FrameStreamParser
  let _dyn_headers: List[(String,String)] = List[(String, String)]

  let _streams: Map[U32, FrameStreamProcessor tag] = Map[U32, FrameStreamProcessor]
  var _scheduler: (FrameScheduler | None) = None

  new create(os: OutStream, request_handler: RequestHandler val) =>
    out = os
    _request_handler = request_handler

  fun ref accepted(con: TCPConnection ref) =>
    out.print("Connection from " + NetAddressUtil.ip_port_str(con.remote_address()))
    _scheduler = FrameScheduler(recover con end)
    None
  
  fun ref connect_failed(con: TCPConnection ref) =>
    out.print("Connection from " + NetAddressUtil.ip_port_str(con.remote_address()) + " failed!")
    _scheduler = None
    None
  
  fun ref received(con: TCPConnection ref, data: Array[U8] iso, times: USize):Bool =>
    _frame_stream_parser.append(consume data)
    _handle_pending_frames()
    true
  
  fun ref _handle_pending_frames() =>
    try
      while _frame_stream_parser.has_next() do
        (let head: FrameHeader val, let payload: Array[U8] val) = _frame_stream_parser.next()?
        //_dump_frameheader(head)
        _handle_frame(head, payload)
      end
    else
      out.print("error handiling package iterator")
    end
  
  fun ref _handle_frame(head: FrameHeader val, payload: Array[U8] val) =>
    let streamid = head.stream_identifier
    if (streamid != 0) and (_streams.contains(streamid) == false) then
      out.print("Creating Stream Processor for " + streamid.string())
      try
        match _scheduler
        | let sched: FrameScheduler tag => 
          _streams.insert(streamid, FrameStreamProcessor(sched, streamid, _request_handler))?
        else error
        end
      else out.print("Failed, No scheduler set up yet!")
      end
    end

    match head.frametype
    | Settings => None
    | WindowUpdate => None
    | Data =>
    let frame: DataFrame val = recover DataFrame(head, payload) end
    try _streams.apply(streamid)?.process(frame) end
    | Headers =>
      let fields: List[(String, String)] iso = recover iso List[(String, String)] end
      for f in _dyn_headers.values() do fields.push(f) end
      let frame: HeadersFrame val = recover HeadersFrame(head, payload, consume box fields) end
      for f in frame.new_headers().values() do _dyn_headers.unshift(f) end


      try
        _streams.apply(streamid)?.process(frame)
      end
    end

  
  fun _dump_frameheader(header: FrameHeader box) =>
    out.print("\n--- BEGIN FRAME ---")
    out.print("Length: " + header.length.string())
    out.print("FrameType: " + FrameTypes.name(header.frametype))
    out.print("Flags: " + header.flags.string())
    out.print("Stream ID: " + header.stream_identifier.string())
    out.print("--- END FRAME ---\n")


/*
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

          match header.frametype
          | Settings => None
          | WindowUpdate => None
          | Headers =>
            let frame = HeadersFrame(header, _dyn_headers, out)
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
*/