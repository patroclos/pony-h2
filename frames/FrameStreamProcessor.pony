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

    _framewriter.write(FrameBuilder.settings())
  
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
  
  fun _evaluate_headers() =>
    let method = _get_header(":method")
    let path = _get_header(":path")

    let template = """
    <!DOCTYPE html>
    <html>
      <head>
        <title>{0}</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
      </head>

      <body>
        <div class="container">
          <h1>{1}</h1>
          <p>A sample page delivered by pony-h2</p>
        </div>
      </body>
    </html>
    """.string()
    .> replace("{0}", "pony-h2 sample")
    .> replace("{1}", "Hello, World!")

    //let headers = List.from([as (String, String): ("content-type", "text/html"); ("content-length", template.size().string())])

    let data: Array[U8] val = recover val Array[U8] .> append(consume template) end

    _send(FrameBuilder.header(8, true, _streamid))
    _send(FrameBuilder.data(data, _streamid))

    match (method, path)
    | (let m: String, let p: String) => _out.print("#" + _streamid.string() +" " + m.upper() + " " + p)
    else
      for kv in headerfields.values() do
        (let n: String, let v: String) = kv
        _out.print("Header: " + n + " => " + v)
      end
    end
  
  fun _get_header(name: String): (String|None) =>
    for hf in headerfields.values() do
      (let n: String, let v: String) = hf
      if n.eq(name) then return v end
    end

  