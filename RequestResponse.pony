use "collections"
use "frames"

primitive GET
primitive POST
primitive PATCH
primitive DELETE
type Method is (GET | POST | PATCH | DELETE)

type Status is U16

class val Request
  var method: Method
  var headers: List[(String, String)] val
  var body: Seq[U8] val

  new create(method': Method, headers': List[(String, String)] val, body': Seq[U8] val) =>
    method = method'
    headers = headers'
    body = body'

class val Response
  var status: (Status | None) = None
  var headers: List[(String, String)] val = recover List[(String, String)] end
  var body: Seq[U8] val = recover val Array[U8] end

  fun ref apply(status': (Status|None), headers': List[(String, String)] val, body': Seq[U8] val) =>
    status = status'
    headers = headers'
    body = body'
  
  fun set_status(code: Status): Response =>
    Response .> apply(code, headers, body)

interface Middleware
  fun on_request(req: Request iso, res: Response iso): (Request iso^, Response iso^)

interface RequestHandler
  fun on_request(req: Request iso, res: Response iso): Response iso^


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

