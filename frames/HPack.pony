use "buffered"
use "collections"

primitive _HuffmanCode
  fun symbol_data(): Array[(U32, U8)] =>
    [as (U32, U8):
      (0x1ff8, 13)
      (0x7fffd8, 23)
      (0xfffffe2, 28)
      (0xfffffe3, 28)
      (0xfffffe4, 28)
      (0xfffffe5, 28)
      (0xfffffe6, 28)
      (0xfffffe7, 28)
      (0xfffffe8, 28)
      (0xffffea, 24)
      (0x3ffffffc, 30)
      (0xfffffe9, 28)
      (0xfffffea, 28)
      (0x3ffffffd, 30)
      (0xfffffeb, 28)
      (0xfffffec, 28)
      (0xfffffed, 28)
      (0xfffffee, 28)
      (0xfffffef, 28)
      (0xffffff0, 28)
      (0xffffff1, 28)
      (0xffffff2, 28)
      (0x3ffffffe, 30)
      (0xffffff3, 28)
      (0xffffff4, 28)
      (0xffffff5, 28)
      (0xffffff6, 28)
      (0xffffff7, 28)
      (0xffffff8, 28)
      (0xffffff9, 28)
      (0xffffffa, 28)
      (0xffffffb, 28)
      (0x14, 6)
      (0x3f8, 10)
      (0x3f9, 10)
      (0xffa, 12)
      (0x1ff9, 13)
      (0x15, 6)
      (0xf8, 8)
      (0x7fa, 11)
      (0x3fa, 10)
      (0x3fb, 10)
      (0xf9, 8)
      (0x7fb, 11)
      (0xfa, 8)
      (0x16, 6)
      (0x17, 6)
      (0x18, 6)
      (0x0, 5)
      (0x1, 5)
      (0x2, 5)
      (0x19, 6)
      (0x1a, 6)
      (0x1b, 6)
      (0x1c, 6)
      (0x1d, 6)
      (0x1e, 6)
      (0x1f, 6)
      (0x5c, 7)
      (0xfb, 8)
      (0x7ffc, 15)
      (0x20, 6)
      (0xffb, 12)
      (0x3fc, 10)
      (0x1ffa, 13)
      (0x21, 6)
      (0x5d, 7)
      (0x5e, 7)
      (0x5f, 7)
      (0x60, 7)
      (0x61, 7)
      (0x62, 7)
      (0x63, 7)
      (0x64, 7)
      (0x65, 7)
      (0x66, 7)
      (0x67, 7)
      (0x68, 7)
      (0x69, 7)
      (0x6a, 7)
      (0x6b, 7)
      (0x6c, 7)
      (0x6d, 7)
      (0x6e, 7)
      (0x6f, 7)
      (0x70, 7)
      (0x71, 7)
      (0x72, 7)
      (0xfc, 8)
      (0x73, 7)
      (0xfd, 8)
      (0x1ffb, 13)
      (0x7fff0, 19)
      (0x1ffc, 13)
      (0x3ffc, 14)
      (0x22, 6)
      (0x7ffd, 15)
      (0x3, 5)
      (0x23, 6)
      (0x4, 5)
      (0x24, 6)
      (0x5, 5)
      (0x25, 6)
      (0x26, 6)
      (0x27, 6)
      (0x6, 5)
      (0x74, 7)
      (0x75, 7)
      (0x28, 6)
      (0x29, 6)
      (0x2a, 6)
      (0x7, 5)
      (0x2b, 6)
      (0x76, 7)
      (0x2c, 6)
      (0x8, 5)
      (0x9, 5)
      (0x2d, 6)
      (0x77, 7)
      (0x78, 7)
      (0x79, 7)
      (0x7a, 7)
      (0x7b, 7)
      (0x7ffe, 15)
      (0x7fc, 11)
      (0x3ffd, 14)
      (0x1ffd, 13)
      (0xffffffc, 28)
      (0xfffe6, 20)
      (0x3fffd2, 22)
      (0xfffe7, 20)
      (0xfffe8, 20)
      (0x3fffd3, 22)
      (0x3fffd4, 22)
      (0x3fffd5, 22)
      (0x7fffd9, 23)
      (0x3fffd6, 22)
      (0x7fffda, 23)
      (0x7fffdb, 23)
      (0x7fffdc, 23)
      (0x7fffdd, 23)
      (0x7fffde, 23)
      (0xffffeb, 24)
      (0x7fffdf, 23)
      (0xffffec, 24)
      (0xffffed, 24)
      (0x3fffd7, 22)
      (0x7fffe0, 23)
      (0xffffee, 24)
      (0x7fffe1, 23)
      (0x7fffe2, 23)
      (0x7fffe3, 23)
      (0x7fffe4, 23)
      (0x1fffdc, 21)
      (0x3fffd8, 22)
      (0x7fffe5, 23)
      (0x3fffd9, 22)
      (0x7fffe6, 23)
      (0x7fffe7, 23)
      (0xffffef, 24)
      (0x3fffda, 22)
      (0x1fffdd, 21)
      (0xfffe9, 20)
      (0x3fffdb, 22)
      (0x3fffdc, 22)
      (0x7fffe8, 23)
      (0x7fffe9, 23)
      (0x1fffde, 21)
      (0x7fffea, 23)
      (0x3fffdd, 22)
      (0x3fffde, 22)
      (0xfffff0, 24)
      (0x1fffdf, 21)
      (0x3fffdf, 22)
      (0x7fffeb, 23)
      (0x7fffec, 23)
      (0x1fffe0, 21)
      (0x1fffe1, 21)
      (0x3fffe0, 22)
      (0x1fffe2, 21)
      (0x7fffed, 23)
      (0x3fffe1, 22)
      (0x7fffee, 23)
      (0x7fffef, 23)
      (0xfffea, 20)
      (0x3fffe2, 22)
      (0x3fffe3, 22)
      (0x3fffe4, 22)
      (0x7ffff0, 23)
      (0x3fffe5, 22)
      (0x3fffe6, 22)
      (0x7ffff1, 23)
      (0x3ffffe0, 26)
      (0x3ffffe1, 26)
      (0xfffeb, 20)
      (0x7fff1, 19)
      (0x3fffe7, 22)
      (0x7ffff2, 23)
      (0x3fffe8, 22)
      (0x1ffffec, 25)
      (0x3ffffe2, 26)
      (0x3ffffe3, 26)
      (0x3ffffe4, 26)
      (0x7ffffde, 27)
      (0x7ffffdf, 27)
      (0x3ffffe5, 26)
      (0xfffff1, 24)
      (0x1ffffed, 25)
      (0x7fff2, 19)
      (0x1fffe3, 21)
      (0x3ffffe6, 26)
      (0x7ffffe0, 27)
      (0x7ffffe1, 27)
      (0x3ffffe7, 26)
      (0x7ffffe2, 27)
      (0xfffff2, 24)
      (0x1fffe4, 21)
      (0x1fffe5, 21)
      (0x3ffffe8, 26)
      (0x3ffffe9, 26)
      (0xffffffd, 28)
      (0x7ffffe3, 27)
      (0x7ffffe4, 27)
      (0x7ffffe5, 27)
      (0xfffec, 20)
      (0xfffff3, 24)
      (0xfffed, 20)
      (0x1fffe6, 21)
      (0x3fffe9, 22)
      (0x1fffe7, 21)
      (0x1fffe8, 21)
      (0x7ffff3, 23)
      (0x3fffea, 22)
      (0x3fffeb, 22)
      (0x1ffffee, 25)
      (0x1ffffef, 25)
      (0xfffff4, 24)
      (0xfffff5, 24)
      (0x3ffffea, 26)
      (0x7ffff4, 23)
      (0x3ffffeb, 26)
      (0x7ffffe6, 27)
      (0x3ffffec, 26)
      (0x3ffffed, 26)
      (0x7ffffe7, 27)
      (0x7ffffe8, 27)
      (0x7ffffe9, 27)
      (0x7ffffea, 27)
      (0x7ffffeb, 27)
      (0xffffffe, 28)
      (0x7ffffec, 27)
      (0x7ffffed, 27)
      (0x7ffffee, 27)
      (0x7ffffef, 27)
      (0x7fffff0, 27)
      (0x3ffffee, 26)
      (0x3fffffff, 30)
    ]

primitive HuffmanCode
  fun decode(data: Array[U8] val):String val =>
    let rv = recover iso String(0) end
    let read = Reader
    read.append(data)

    let decode_data = _HuffmanCode.symbol_data()

    try
      var current:U32 = 0
      var num_bits:U8 = 0

      while true do
        let byte = read.u8()?

        for bit in [as U8: 7;6;5;4;3;2;1;0].values() do
          let v = byte and (1<<bit)

          current = (current << 1) or U32.from[U8](if v != 0 then 1 else 0 end)
          num_bits = num_bits + 1

          try
            let char:U8 = U8.from[USize](decode_data.find((current, num_bits))?)
            rv.push(char)
            current = 0
            num_bits = 0
          end

        end
      end
    end

    consume val rv
  
  /*
  fun encode(data: String box): String val =>
    let buf: Array[U8] trn = recover trn Array[U8] end

    var byte: U8 = 0
    var bit: U8 = 0

    for c in data.values() do
      (let code:U32, let len: U8) = _HuffmanCode.symbol_data().apply(c)?
      let code_bytes = Array[U8]
        .> push(code and 0xff)
        .> push(code.shr(8) and 0xff)
        .> push(code.shr(16) and 0xff)
        .> push(code.shr(24) and 0xff)
      
      var code_bit_index:U8 = 0
      while code_bit_index < len do
        // TODO push len bits
        code_bit_index = code_bit_index + 8
      end
    end

    if byte > 0 then
      buf.push(byte)
    end

    recover val String.from_array(consume val buf) end
    */

primitive Huffman
type StringEncoding is (Huffman | None )

primitive HPack
  fun read_string(reader: Reader ref): String? =>
    try
      (let encoding: StringEncoding, let length: USize) = _read_string_meta(reader)?
      let raw = recover val reader.block(length)? end

      match encoding
      | Huffman => HuffmanCode.decode(consume raw)
      | None => String.from_array(raw)
      end
    else
      error
    end
  
  fun read_integer(reader: Reader ref, start_val: U8, start_bit_width:U8 = 8): USize? =>
    var value: USize = USize.from[U8](start_val)

    if start_val < 1.shl(start_bit_width).sub(1) then return value end

    var m: USize = 0
    var b: U8 = 0

    repeat
      b = try reader.u8()? else error end
      value = value + USize.from[U8](b and 127).mul(USize(1).shl(m))
      m = m + 7
    until b.op_and(128) != 128 end

    value
  
  fun encode_integer(value: USize, start_bit_width: U8 = 8): Array[U8] =>
    if value < USize.from[U8](1.shl(start_bit_width).sub(1)) then
      return [as U8: U8.from[USize](value)]
    end

    let buffer = Array[U8]

    buffer.push(1.shl(start_bit_width) - 1)

    var remainder = value - USize.from[U8](1.shl(start_bit_width) - 1)

    while remainder >= 128 do
      buffer.push(U8.from[USize]((remainder % 128) + 128))
      remainder = remainder / 128
    end

    buffer .> push(U8.from[USize](remainder))

  
  fun _read_string_meta(reader: Reader ref): (StringEncoding, USize)? =>
    try
      let meta = reader.u8()?
      let encoding: StringEncoding = if meta.op_and(128) != 0 then Huffman else None end
      let length: USize = read_integer(reader, meta.op_and(127), 7)?

      (encoding, length)
    else error end