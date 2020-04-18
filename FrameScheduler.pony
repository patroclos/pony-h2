use "net"
use "collections"
use "frames"

actor FrameScheduler is FrameWriter
  let _pending: List[Frame] = List[Frame]
  let _connection: TCPConnection tag

  new create(connection: TCPConnection tag) =>
    _connection = connection
  
  be write(frame: Frame val) =>
    for x in _split_data_frame(frame).values() do
      _pending.push(x)
    end
    _send_pending()
  
  fun tag _split_data_frame(frame: Frame val, max_size: USize = 16384): Seq[Frame val] val =>
    if (not (frame.header().frametype is Data)) or (frame.payload().size() <= max_size) then
      recover val [frame] end
    else
      let size = frame.payload().size()
      var i: USize = 0
      let accum = recover trn List[Frame] end
      while i < size do
        let left = size - i
        let frameSize = left.min(16384)
        let flags = if (left - frameSize) > 0 then
            frame.header().flags and (not FrameHeaderFlags.data_EndStream())
          else
            frame.header().flags and (FrameHeaderFlags.data_EndStream())
          end
        let header = FrameHeader.from_values(frameSize, Data, flags, frame.header().stream_identifier)
        let chunk = frame.payload().trim(i, i + frameSize)
        accum.push(DataFrame(header, chunk))

        i = i + left.min(16384)
      end
      consume val accum
    end
  
  fun ref _send_pending() =>
    while _pending.size() > 0 do
      try _connection.write(_pending.shift()?.to_bytes()) else break end
    end

  fun dispose() => None