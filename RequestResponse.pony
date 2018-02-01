use "collections"
use "frames"

type Status is U16

class box Request
  let headers: List[(String, String)] val
  let body: Array[U8] val

  new val create(headers': List[(String, String)] val, body': Array[U8] val) =>
    headers = headers'
    body = body'
  
  fun header(name: String): (String | None) =>
    for hf in headers.values() do
      if hf._1.eq(name) then return hf._2 end
    end

class box Response
  var headers: List[(String, Stringable)] val = recover List[(String, Stringable)] end
  var body: Array[U8] val = recover val Array[U8] end
  let _stream: U32

  new create(stream: U32) =>
    _stream = stream
  
  fun box apply(status: Status): Array[Frame] val =>
    let ext_headers = recover val
      List[(String, Stringable)]
      .> push((":status", status))
      .> push(("content-length", body.size()))
      .> append(headers)
    end
    let headerFrame = FrameBuilder.header_list(ext_headers, true, _stream)
    let dataFrame = FrameBuilder.data(body, _stream)

    recover val [as Frame: headerFrame; dataFrame] end

//interface Middleware
//  fun on_request(req: Request iso, res: Response iso): (Request iso^, Response iso^)

interface val RequestHandler
  fun on_request(req: Request val, res: Response trn): (Response val, Status)

/*
actor SomewhereOverTheRainbow
  let _writer: FrameWriter
  let _stream: U32
  let _handler: RequestHandler iso
  let _middleware: Seq[Middleware] val

  new create(handler: RequestHandler iso, middleware: Seq[Middleware] val, writer: FrameWriter tag, stream: U32) =>
    _writer = writer
    _stream = stream
    _handler = consume handler
    _middleware = middleware
  
  be handle(req': Request iso) =>
    var req: Request iso = consume req'
    var res: Response iso = recover Response end
    for mw in _middleware.values() do
      (let treq: Request iso, let tres: Response iso) = mw.on_request(consume req, consume res)
      req = consume treq
      res = consume tres
    end

    _send(_handler.on_request(consume req, consume res))
  
  fun _send(res: Response iso) =>
    // TODO build frames for headers and data and enqueue those
    None

*/