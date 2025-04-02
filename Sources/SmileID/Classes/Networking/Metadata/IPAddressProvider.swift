import Foundation

func getIPAddress(useIPv4: Bool) -> String {
    var address = ""
    var ifaddr: UnsafeMutablePointer<ifaddrs>?

    guard getifaddrs(&ifaddr) == 0 else {
        return ""
    }

    var ptr = ifaddr
    while ptr != nil {
        defer { ptr = ptr?.pointee.ifa_next }

        guard let interface = ptr?.pointee else {
            return ""
        }

        let addrFamily = interface.ifa_addr.pointee.sa_family
        if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
            let name = String(cString: interface.ifa_name)
            if name == "en0" || name == "en1" || name == "pdp_ip0"
                || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(
                    interface.ifa_addr,
                    socklen_t(interface.ifa_addr.pointee.sa_len),
                    &hostname, socklen_t(hostname.count),
                    nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)

                if (useIPv4 && addrFamily == UInt8(AF_INET))
                    || (!useIPv4 && addrFamily == UInt8(AF_INET6)) {
                    if !useIPv4 {
                        if let percentIndex = address.firstIndex(of: "%") {
                            address = String(address[..<percentIndex])
                                .uppercased()
                        } else {
                            address = address.uppercased()
                        }
                    }
                    break
                }
            }
        }
    }

    freeifaddrs(ifaddr)
    return address
}
