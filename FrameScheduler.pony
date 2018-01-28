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
    reshedule()
  
  fun reshedule() => None

  fun dispose() => None