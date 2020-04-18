class val DataFrame is Frame
  let _header: FrameHeader val
  let _payload: FramePayload val

  new val create(header': FrameHeader val, payload': FramePayload val) =>
    _header = header'
    _payload = payload'

  fun box header(): FrameHeader val => _header
  fun box payload(): FramePayload val => _payload

  fun box data(): Array[U8] val =>
    // TODO implement padding and (optional encoding?)
    _payload