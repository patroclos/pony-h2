use "collections"
use "buffered"

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
  
  fun encode_field_statically(name: String val, value': Stringable val): Array[U8] =>
    let rv = recover trn Array[U8] end
    rv.push(16) // 00010000 (literal never indexed)

    let value = recover val value'.string() end

    let len_name = name.size()
    let len_value = value.size()

    for b in HPack.encode_integer(len_name).values() do
      rv.push(b)
    end

    for b in name.values() do
      rv.push(b)
    end

    for b in HPack.encode_integer(len_value).values() do
      rv.push(b)
    end

    for b in value.values() do
      rv.push(b)
    end

    rv

  
  fun encode_field(name: String val, value': Stringable val, dynamic_table: (List[(String, String)] | None)): Array[U8]? =>
    encode_field_statically(name, value')
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
