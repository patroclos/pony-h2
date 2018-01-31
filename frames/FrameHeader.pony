use "buffered"

primitive FrameHeaderFlags
  fun data_EndStream(): U8 => 1

  fun headers_EndStream(): U8 => 1
  fun headers_EndHeaders(): U8 => 1 << 2
  fun headers_Padded(): U8 => 1 << 3
  fun headers_Priority(): U8 => 1 << 5

  fun flags_match(flags: U8, matches: U8):Bool => (flags and matches) == matches

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
  
  new copy(from: FrameHeader box) =>
    length = from.length
    frametype = from.frametype
    flags = from.flags
    stream_identifier = from.stream_identifier
  
  fun has_flags(flags': U8): Bool =>
    FrameHeaderFlags.flags_match(flags, flags')
  
  fun to_bytes(): Array[U8] =>
    let wb = Writer
    wb.u32_be((U32.from[USize](length) << 8) or (U32.from[U8](FrameTypes.code(frametype))))
    wb.u8(flags)
    wb.u32_be(stream_identifier)
    let arrs: Array[ByteSeq] = wb.done()
    let buf = Array[U8]

    for a in arrs.values() do
      let values = match a
        | let s: Array[U8] val => s.values()
        | let s: String val => s.values()
      end

      for v in values do
        buf.push(v)
      end
    end

    buf