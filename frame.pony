use "buffered"
use "collections"

primitive Data

primitive Headers
  // https://tools.ietf.org/html/rfc7541#appendix-A Static Headers Table Definition
  fun authority(): U8 => indexed(1)
  fun method_get(): U8 => indexed(2)
  fun method_post(): U8 => indexed(3)
  fun path_root(): U8 => indexed(4)
  fun path_index(): U8 => indexed(5)
  fun scheme_http(): U8 => indexed(6)
  fun scheme_https(): U8 => indexed(7)
  fun status_200(): U8 => indexed(8)
  fun status_204(): U8 => indexed(8)
  fun status_206(): U8 => indexed(8)
  fun status_304(): U8 => indexed(8)
  fun status_400(): U8 => indexed(8)
  fun status_404(): U8 => indexed(8)
  fun status_500(): U8 => indexed(8)

  // https://tools.ietf.org/html/rfc7541#section-6.1 Indexed Header Field Representation
  fun indexed(index: U8): U8 =>
    (index and (0xff >> 1)) or (0x1 << 7)

primitive Priority
primitive RstStream
primitive Settings
primitive PushPromise
primitive Ping
primitive Goaway
primitive WindowUpdate
primitive Continuation

type FrameType is (Data|Headers|Priority|RstStream|Settings|PushPromise|Ping|Goaway|WindowUpdate|Continuation)
  
primitive FrameTypes
  fun tag apply(): Array[FrameType] =>
    [Data; Headers; Priority; RstStream; Settings; PushPromise; Ping; Goaway; WindowUpdate; Continuation]

  fun code(frametype: FrameType): U8 =>
    match frametype
    | Data => 0x0
    | Headers => 0x1
    | Priority => 0x2
    | RstStream => 0x3
    | Settings => 0x4
    | PushPromise => 0x5
    | Ping => 0x6
    | Goaway => 0x7
    | WindowUpdate => 0x8
    | Continuation => 0x9
    end
  
  fun name(frametype: FrameType): String val =>
    match frametype
    | Data => "Data"
    | Headers => "Headers"
    | Priority => "Priority"
    | RstStream => "RST_Stream"
    | Settings => "Settings"
    | PushPromise => "PushPromise"
    | Ping => "Ping"
    | Goaway => "Goaway"
    | WindowUpdate => "WindowUpdate"
    | Continuation => "Continuation"
    end


class FrameHeader
  let length: USize
  let frametype: FrameType
  let flags: U8
  let stream_identifier: U32

  new create(buf: Array[U8] iso)? =>
    let rb = Reader
    rb.append(consume buf)

    let dword = rb.u32_be()?
    let frametype_code = USize.from[U32](dword and 0xff)

    length = USize.from[U32](dword >> 8)
    frametype = FrameTypes().apply(frametype_code)?
    flags = rb.u8()?
    stream_identifier = rb.u32_be()? and (0xffffffff >> 1)
  
  new from_values(length': USize, ft: FrameType, flags': U8, streamid: U32) =>
    length = length'
    frametype = ft
    flags = flags'
    stream_identifier = streamid
  
  fun to_bytes(): Array[U8]? =>
    let wb = Writer
    wb.u32_be((U32.from[USize](length) << 8) or (U32.from[U8](FrameTypes.code(frametype))))
    wb.u8(flags)
    wb.u32_be(stream_identifier)
    let arrs: Array[ByteSeq] = wb.done()
    let buf = Array[U8]

    for a in arrs.values() do
      for v in (a as Array[U8] val).values() do
        buf.push(v)
      end
    end

    buf

    //length = (U32.from[U8](buf.apply(0)?) << 16) or (U32.from[U8](buf.apply(1)?) << 8) or U32.from[U8](buf.apply(2)?)
    //var frametype_code = USize.from[U8](buf.apply(3)?)
    //flags = buf.apply(4)?
    //stream_identifier = 0
