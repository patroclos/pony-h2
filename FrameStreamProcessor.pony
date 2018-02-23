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
  let _request_handler: RequestHandler val

  var _headerfields: List[(String, String)] trn = recover trn List[(String, String)] end
  var _data: Array[U8] trn = recover trn Array[U8] end

  new create(writer: FrameWriter tag, streamid: U32, request_handler: RequestHandler val) =>
    _streamid = streamid
    _frames = Array[Frame]
    _framewriter = consume writer
    _request_handler = request_handler

  
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
        if wants_data() == false then
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
    let hcopy = _headerfields = recover trn List[(String, String)] end
    let dcopy = _data = recover trn Array[U8] end

    let req = Request.create(consume val hcopy, consume val dcopy)
    (let response: Response val, let status: Status) = _request_handler.on_request(req, recover trn Response(_streamid) end)

    for frame in response(status).values() do
      _send(frame)
    end

/*
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

    let response = Response(_streamid)
    response.headers = recover val
      List[(String, Stringable)]
      .> push(("x-powered-by", "pony-h2"))
      .> push(("set-cookie", "bullshit=yes"))
    end

    response.body = (consume val template).array()

    for frame in response(Status(200)).values() do
      _send(frame)
    end
    */

/*
    let data: Array[U8] val = recover val Array[U8] .> append(consume template) end

    let headers: List[(String, Stringable)] val = recover val
      List[(String, Stringable)]
      .> push((":status", U16(200)))
      .> push(("content-length", data.size()))
      .> push(("x-powered-by", "pony-h2"))
      .> push(("set-cookie", "stupidshit=getrektson"))
    end

    //_send(FrameBuilder.header(8, true, _streamid))
    _send(FrameBuilder.header_list(headers, true, _streamid))
    _send(FrameBuilder.data(data, _streamid))
    */
  
  fun _get_header(name: String): (String|None) =>
    for hf in _headerfields.values() do
      if hf._1.eq(name) then return hf._2 end
    end

  