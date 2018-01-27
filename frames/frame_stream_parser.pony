use "buffered"

class FrameStreamParser is Iterator[(FrameHeader, Array[U8])]
  let _reader: Reader
  var _current_head: (FrameHeader|None) = None
  var _begin_offset: USize

  new create(begin_offset: USize = 24) =>
    _reader = Reader
    _begin_offset = begin_offset

  fun ref append(data: Array[U8] val) =>
    _reader.append(data)
  
  fun ref _get_header(): FrameHeader? =>
    match _current_head
    | None =>
      try
        if _begin_offset > 0 then _reader.skip(_begin_offset = 0)? end
        let bytes = _reader.block(9)?
        let head: FrameHeader = FrameHeader(consume bytes)?
        _current_head = head
        head
      else error
      end
    else error
    end
  
  fun ref has_next(): Bool =>
    match _current_head
    | let head: FrameHeader => _reader.size() >= head.length
    | None => try _current_head = _get_header()?; has_next() else false end
    end

  fun ref next(): (FrameHeader, Array[U8])? =>
    try
      match _current_head
      | let head: FrameHeader => 
        let payload: Array[U8] = _reader.block(head.length)?
        _current_head = None
        (head, payload)
      else error
      end
    else error
    end

