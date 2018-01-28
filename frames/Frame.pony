type FramePayload is Array[U8]

trait val Frame
  fun header(): FrameHeader val
  fun payload(): FramePayload val

  fun has_flags(flags: U8): Bool =>
    header().has_flags(flags)

  fun to_bytes(): FramePayload? =>
    try header().to_bytes() .> append(payload()) else error end