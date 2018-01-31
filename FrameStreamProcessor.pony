use "net"
use "collections"
use "frames"

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

  var _headerfields: List[(String, String)] trn = recover trn List[(String, String)] end
  var _data: Array[U8] trn = recover trn Array[U8] end

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
    | let data: DataFrame val =>
    _data.append(data.data())

    if data.has_flags(FrameHeaderFlags.data_EndStream()) then
      _flush_request()
    end
    | let headers: HeadersFrame val =>
      for f in headers.fields().values() do _headerfields.push(f) end

      if headers.has_flags(FrameHeaderFlags.headers_EndHeaders()) then
        if wants_data() then
          _out.print("Waiting for data before processing request")
        else
          _flush_request()
        end
      end
    end
  
  fun box wants_data(): Bool =>
    match _get_header("content-length")
    | None => false
    | "0" => false
    else true
    end
  
  fun ref _flush_request() =>
    let method = _get_header(":method")
    let path = _get_header(":path")

    let hcopy = _headerfields = recover trn List[(String, String)] end
    let dcopy = _data = recover trn Array[U8] end

/*
    let req = match method
    | let m: String => 
    Request.create(GET, consume val hcopy, consume val dcopy)
    else None
    end

    match req
    | let r: Request val =>
    _out.print("Request: " + String.from_array(r.body))
    end
    */

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

    let data: Array[U8] val = recover val Array[U8] .> append(consume template) end


    _send(FrameBuilder.header(8, true, _streamid))
    _send(FrameBuilder.data(data, _streamid))

    /*
    match (method, path)
    | (let m: String, let p: String) => _out.print("#" + _streamid.string() +" " + m.upper() + " " + p)
    else
      for kv in _headerfields.values() do
        (let n: String, let v: String) = kv
        _out.print("Header: " + n + " => " + v)
      end
    end
    */
  
  fun _get_header(name: String): (String|None) =>
    for hf in _headerfields.values() do
      (let n: String, let v: String) = hf
      if n.eq(name) then return v end
    end

  