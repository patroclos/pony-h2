primitive FrameBuilder
  fun settings(): Frame val => _SettingsFrame
  fun header(index: U8 val, eoh: Bool val, stream: U32 val): Frame val => _Headers(index, eoh, stream)
  fun data(data': Array[U8] val, stream: U32 val): Frame val => _Data(data', stream)

class _SettingsFrame is Frame
  let _header: FrameHeader val

  new val create() =>
    _header = recover val FrameHeader.from_values(0, Settings, 0, 0) end
  
  fun header(): FrameHeader val => _header
  fun payload(): Array[U8] val => recover val Array[U8] end

class _Headers is Frame
  let _header: FrameHeader val
  let _payload: FramePayload val

  new val create(index: U8 val, eoh: Bool val, stream: U32 val) =>
    _header = recover val FrameHeader.from_values(1, Headers, if eoh then 4 else 0 end, stream) end
    _payload = recover val [as U8: index.op_and(127).op_or(128)] end
  
  fun header(): FrameHeader val => _header
  fun payload(): FramePayload val => _payload

class _Data is Frame
  let _header: FrameHeader val
  let _payload: FramePayload val

  new val create(data: Array[U8] val, stream: U32 val) =>
    _header = recover val FrameHeader.from_values(data.size(), Data, 1, stream) end
    _payload = data
  
  fun header(): FrameHeader val => _header
  fun payload(): FramePayload val => _payload