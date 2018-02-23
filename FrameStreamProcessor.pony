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
  fun _get_header(name: String): (String|None) =>
    for hf in _headerfields.values() do
      if hf._1.eq(name) then return hf._2 end
    end

  