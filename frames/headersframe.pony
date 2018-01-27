use "buffered"
use "collections"
use "crypto"

/*
 +---------------+
 |Pad Length? (8)|
 +-+-------------+-----------------------------------------------+
 |E|                 Stream Dependency? (31)                     |
 +-+-------------+-----------------------------------------------+
 |  Weight? (8)  |
 +-+-------------+-----------------------------------------------+
 |                   Header Block Fragment (*)                 ...
 +---------------------------------------------------------------+
 |                           Padding (*)                       ...
 +---------------------------------------------------------------+
*/

primitive _Flags
  fun end_stream():U8 => 1
  fun end_headers():U8 => 1 << 2

  // toggles pad length and padding fields
  fun padded():U8 => 1 << 3

  // toggles exclusive flag(E), stream dependency and weight
  fun priority():U8 => 1 << 5

primitive Huffman
type StringEncoding is (Huffman|None)

class HeadersFrame
  let _fields: List[(String, String)]
  let _header: FrameHeader val
  let _dynamic_table: List[(String, String)] ref

  new create(header': FrameHeader val, dynamic_table: List[(String, String)] ref) =>
    _fields = List[(String, String)]
    _header = header'
    _dynamic_table = dynamic_table
  
  fun header(): FrameHeader val =>
    _header
  
  fun fields(): List[(String, String)] box =>
    _fields
  
  fun ref parse_fields(payload: Array[U8] val, out: OutStream) =>
    let rb: Reader ref = Reader
    rb.append(payload)

    let is_padded = (_header.flags and _Flags.padded()) != 0
    let has_priority = (_header.flags and _Flags.priority()) != 0

    try
      let pad_length = if is_padded then rb.u8()? else 0 end
      
      let exclusive_and_stream_dependency = if has_priority then rb.u32_be()? else 0 end
      let exclusive: Bool = (exclusive_and_stream_dependency and (1<<31)) != 0
      let stream_dependency = exclusive_and_stream_dependency and 0x7fffffff
      let weight = if has_priority then rb.u8()? else 0 end

      while rb.size() > 0 do
        try 
          _read_field(rb, out)? 
          if is_padded then rb.skip(USize.from[U8](pad_length))? end
        else 
          out.print("!Error")
          break 
        end
      end
    end

    out.print("\n" + rb.size().string() + " bytes left in payload")
    try out.print(ToHexString(rb.block(rb.size())?)) else out.print("Error printing remainder") end
  
  fun ref _set_header(name: String, value: String) =>
    _fields.push((name, value))
  
  fun ref _get_header(index: U8): (String|(String,String)|None) =>
    try
      if USize.from[U8](index) > HeaderField.static_headers().size() then 
        let adjusted_index = USize.from[U8](index) - HeaderField.num_static_headers() - 2
        _dynamic_table.apply(adjusted_index)?
      else HeaderField.get_data(index) end
    end


  fun ref _read_field(rb: Reader, out: OutStream)? =>
    try
      let header_field_begin = rb.u8()?
      let is_indexed = (header_field_begin and (1<<7)) != 0

      if is_indexed then
        let index = header_field_begin and (0xff >> 1)

        match _get_header(index)
        | let name: String => _set_header(name, "")
        | (let name: String, let value: String) => _set_header(name, value)
        | None => 
          out.print("Error accessing indexed header at: " + index.string())
          out.print("Num Static: " + HeaderField.num_static_headers().string() + " Num Dynamic: " + _dynamic_table.size().string())
          error
        end
      else // not indexed
        // literal types: with indexing, without indexing, never indexed
        let incremental_index = (header_field_begin and (1<<6)) != 0

        let name_index_mask: U8 val = recover if incremental_index then U8(0b111111) else U8(0b1111) end end
        let name_index = (header_field_begin and (consume name_index_mask))
        let is_name_indexed = name_index != 0
        let name = if is_name_indexed then
            out.print("Matching")
            match _get_header(name_index)
                | let name: String => name
                | (let name: String, let value: String) => name
                | None => out.print("Error accessing indexed name at: " + name_index.string());error
            end
          else
            out.print("Reading")
            _read_string(rb, out)?
          end
          out.print(name)


        if incremental_index then
          let value = try _read_string(rb, out)? else out.print("Error reading " + name); error end
          _set_header(name, value)
          _dynamic_table.unshift((name,value))
        else
          let value = try _read_string(rb, out)? else out.print("Error reading " + name); error end
          _set_header(name,value)
        end
      end

    else // try failed
      out.print("Error decoding headers")
      error
    end

  fun _read_string(rb: Reader, out: OutStream):String? =>
    try
      //let str_meta = rb.u8()?
      //let is_huffman = (str_meta and (1<<7)) != 0
      //let length = USize.from[U8](str_meta and (0xff >> 1))

      (let encoding: StringEncoding, let length: USize) = _read_string_meta(rb)?

      var raw = try rb.block(length)? else out.print("cant read string block"); error end

      match encoding
      | Huffman => HPackDecoder.decode(consume raw)
      | None => String.from_array(consume raw)
      end
    else
      out.print("Error reading string")
      error
    end
  
  fun _read_string_meta(rb: Reader): (StringEncoding, USize)? =>
    let meta = rb.u8()?
    let encoding = if ((meta and (1<<7)) != 0) then Huffman else None end
    var length = USize.from[U8](meta and (0xff >> 1))

    if length < (0xff >> 1) then return (encoding, length) end

    var m:USize = 0
    var b:U8=0
    repeat
      b = rb.u8()?
      length = length + (USize.from[U8](b and (0xff >> 1)) * (USize(1)<<m))
      m = m + 7
    until (b and (0xff>>1)) != (0xff>>1) end

    (encoding, length)