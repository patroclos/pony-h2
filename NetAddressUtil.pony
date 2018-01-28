use "net"

primitive NetAddressUtil
  fun ip_port_str(na: NetAddress val): String val =>
    let addr = na.addr
      (addr and 0xff).string() + "." + ((addr >> 8) and 0xff).string() + "." + ((addr >> 16) and 0xff).string() + "." + ((addr >> 24) and 0xff).string() + ":" + na.port.string()