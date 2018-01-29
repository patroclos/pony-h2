type FramePayload is Array[U8]

trait val Frame
  fun header(): FrameHeader val
  fun payload(): FramePayload val

  fun has_flags(flags: U8): Bool =>
    header().has_flags(flags)

  fun to_bytes(): Array[U8] val =>
    let head = header().to_bytes()
    let body = payload()
    /*
    recover Array[U8](head.size() + body.size())
    .> append(head)
    .> append(body)
    end
    */
    //recover val Array[U8] end
    recover header().to_bytes() .> append(payload()) end