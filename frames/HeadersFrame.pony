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


class HeadersFrame is Frame
  let _header: FrameHeader val
  let _payload: FramePayload val
  let _fields: List[(String, String)]
  let _dynamic_table: List[(String, String)] box
  let _new_dynamic: List[(String, String)] = List[(String, String)]

  new create(header': FrameHeader val, payload': FramePayload val, dynamic_table: List[(String, String)] box) =>
    _header = header'
    _payload = payload'
    _fields = List[(String, String)]
    _dynamic_table = dynamic_table
    _parse_fields()
  
  fun header(): FrameHeader val =>
    _header
  
  fun payload(): FramePayload val =>
    _payload
  
  fun new_headers(): List[(String, String)] box =>
    _new_dynamic
  
  fun fields(): List[(String, String)] box =>
    _fields
  
  fun ref _parse_fields() =>
    let rb: Reader ref = Reader
    rb.append(_payload)

    let is_padded = _header.has_flags(FrameHeaderFlags.headers_Padded())
    let has_priority = _header.has_flags(FrameHeaderFlags.headers_Priority())

    try
      let pad_length = if is_padded then rb.u8()? else 0 end
      
      let exclusive_and_stream_dependency = if has_priority then rb.u32_be()? else 0 end
      let exclusive: Bool = (exclusive_and_stream_dependency and (1<<31)) != 0
      let stream_dependency = exclusive_and_stream_dependency and 0x7fffffff
      let weight = if has_priority then rb.u8()? else 0 end

      while rb.size() > 0 do
        try 
          _read_field(rb)?
          if is_padded then rb.skip(USize.from[U8](pad_length))? end
        else 
          break 
        end
      end
    end
  
  fun ref _set_header(name: String, value: String) =>
    _fields.push((name, value))
  
  fun ref _get_header(index: USize): (String|(String,String)|None) =>
    try
      if index > HeaderField.static_headers().size() then
        let adjusted_index = index - HeaderField.num_static_headers() - 1
        if adjusted_index < _new_dynamic.size() then 
          _dynamic_table.apply(adjusted_index)?
        else
          _new_dynamic.apply(adjusted_index)?
        end
      else HeaderField.get_data(index) end
    end


  fun ref _read_field(rb: Reader)? =>
    try
      let header_field_begin = rb.u8()?
      let is_indexed = (header_field_begin and (1<<7)) != 0

      if is_indexed then
        let index = HPack.read_integer(rb, header_field_begin and (0xff >> 1), 7)?

        match _get_header(index)
        | let name: String => _set_header(name, "")
        | (let name: String, let value: String) => _set_header(name, value)
        | None => 
          error
        end
      else // not indexed
        // literal types: with indexing, without indexing, never indexed
        let incremental_index = (header_field_begin and (1<<6)) != 0

        let name_index_mask: U8 val = recover if incremental_index then U8(0b111111) else U8(0b1111) end end
        let name_index = HPack.read_integer(rb, header_field_begin and (consume name_index_mask), if incremental_index then 6 else 4 end)?
        let is_name_indexed = name_index != 0
        let name = if is_name_indexed then
            match _get_header(name_index)
                | let name: String => name
                | (let name: String, let value: String) => name
                | None => error
            end
          else
            HPack.read_string(rb)?
          end


        if incremental_index then
          let value = try HPack.read_string(rb)? else error end
          _set_header(name, value)
          _new_dynamic.unshift((name,value))
        else
          let value = try HPack.read_string(rb)? else error end
          _set_header(name,value)
        end
      end

    else // try failed
      error
    end
