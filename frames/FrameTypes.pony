use "collections"

primitive Data
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
