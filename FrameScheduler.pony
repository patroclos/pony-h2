use "net"
use "collections"
use "frames"

actor FrameScheduler is FrameWriter
  let _pending: List[Frame] = List[Frame]
  let _connection: TCPConnection tag

  new create(connection: TCPConnection tag) =>
    _connection = connection
  
  be write(frame: Frame val) =>
    _pending.push(frame)
    _send_pending()
  
  fun ref _send_pending() =>
    while _pending.size() > 0 do
      try _connection.write(_pending.shift()?.to_bytes()) else break end
    end

  fun dispose() => None