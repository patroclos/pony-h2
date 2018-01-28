use "net"
use "collections"

trait tag FrameWriter
  be write(frame: Frame val)

primitive _Stage
  fun wait_headers(): U8 tag => 0
  fun wait_data(): U8 tag => 1

actor FrameStreamProcessor
  let _streamid: U32
  let _frames: Seq[Frame]
  let _framewriter: FrameWriter tag
  let _out: OutStream

  let headerfields: List[(String, String)] = List[(String, String)]

  new create(writer: FrameWriter tag, streamid: U32, out: OutStream) =>
    _streamid = streamid
    _frames = Array[Frame]
    _framewriter = consume writer
    _out = out
  
  be _send(frame: Frame val) =>
    _framewriter.write(frame)
  
  be process(frame: Frame val) =>
    match frame
    | let headers: HeadersFrame val =>
      for f in headers.fields().values() do headerfields.push(f) end

      if headers.has_flags(FrameHeaderFlags.headers_EndHeaders()) then
        _evaluate_headers()
        _out.print("Evaluating " + headerfields.size().string() + " Headers")
      end
    end
    _send(frame) // TODO do something reasonable, like actually responding
  
  fun _evaluate_headers() =>
    try
      let method = _get_header(":method") as String
      let path = _get_header(":path") as String

      _out.print("#" + _streamid.string() +" " + method.upper() + " " + path)
    end
  
  fun _get_header(name: String): (String|None) =>
    for hf in headerfields.values() do
      (let n: String, let v: String) = hf
      if n.eq(name) then return v end
    end

  
/*
*/