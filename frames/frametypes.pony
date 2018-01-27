use "collections"

primitive Data

// TODO non-static literal or literal-incrementally-indexed header fields
primitive HeaderField

  // https://tools.ietf.org/html/rfc7541#appendix-A Static Headers Table Definition
  // https://tools.ietf.org/html/rfc7541#section-6.1 Indexed Header Field Representation
  fun indexed(index: U8): U8 =>
    (index and (0xff >> 1)) or (0x1 << 7)
  
  fun _get_name_index(name: String val, dynamic_table: (List[(String, String)] val | None)): (U8 | None) =>
    try
      let headers = static_headers()

      match dynamic_table
      | let table: List[(String,String)] val => headers.concat(table.values())
      end

      var i: USize = 1
      while i < headers.size() do
        match headers.apply(i - 1)?
        | let n: String =>
            if n.eq(name) then return U8.from[USize](i) end
        | (let n: String, let v: String) =>
            if n.eq(name) then return U8.from[USize](i) end
        end

        i = i + 1
      end

      None
    end



  fun get_index(name: String val, value': Stringable val, dynamic_table: (List[(String, String)] val|None)): (U8|None)=>
    let value = recover val value'.string() end
    try
      let headers = static_headers()

      var i: USize = 0
      var name_index: (U8|None) = None
      var match_strings: Bool = true

      while i < num_static_headers() do i = i + 1
        let header = headers.apply(i - 1)?
        match headers.apply(i - 1)?
        | let h: String if match_strings => 
          if h.eq(name) then 
            name_index = U8.from[USize](i)
            match_strings = false
          end
        | (let h:String, let v:String) => 
          if h.eq(name) then 
            name_index = U8.from[USize](i)
            match_strings = false

            if v.eq(value) then
              return name_index
            end
          end
        end
      end

      None
    end
  
  fun encode_header(name: String val, value': Stringable val, dynamic_table: (List[(String, String)] val|None)): Array[U8] ref? =>
    try return [indexed(get_index(name, value', dynamic_table) as U8)] end
    error

  fun num_static_headers(): USize => 61
  fun static_headers(): Seq[(String|(String,String))] =>
    [
      ":authority"

      (":method", "GET")
      (":method", "POST")

      (":path", "/")
      (":path", "/index.html")

      (":scheme", "http")
      (":scheme", "https")

      (":status", "200")
      (":status", "204")
      (":status", "206")
      (":status", "304")
      (":status", "400")
      (":status", "404")
      (":status", "500")

      "accept-charset"
      ("accept-encoding", "gzip, deflate")
      "accept-language"
      "accept-ranges"
      "accept"
      "access-control-allow-origin"
      "age"
      "allow"
      "authorization"
      "cache-control"
      "content-disposition"
      "content-encoding"
      "content-language"
      "content-length"
      "content-location"
      "content-range"
      "content-type"
      "cookie"
      "date"
      "etag"
      "expect"
      "expires"
      "from"
      "host"
      "if-match"
      "if-modified-since"
      "if-none-match"
      "if-range"
      "if-unmodified-since"
      "last-modified"
      "link"
      "location"
      "max-forwards"
      "proxy-authentication"
      "proxy-authorization"
      "range"
      "referer"
      "refresh"
      "retry-after"
      "server"
      "set-cookie"
      "strict-transport-security"
      "transfer-encoding"
      "user-agent"
      "vary"
      "via"
      "www-authenticate"
    ]
  
  fun get_data(index: USize): ((String|(String, String))|None) =>
    try static_headers().apply(index - 1)? else None end

primitive Headers
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
