import Foundation

extension ProcessInfo {
    /// Returns the available physical memory in MB
    var availableMemoryInMB: Int {
        // Get physical memory in bytes
        let physicalMemory = self.physicalMemory

        // Convert to MB (1 MB = 1,048,576 bytes)
        let memoryInMB = physicalMemory / 1_048_576

        return Int(memoryInMB)
    }

    /// Returns the system architecture (e.g., "ARM64", "x86_64")
    var systemArchitecture: String {
        #if arch(arm64)
            return "arm64"
        #elseif arch(x86_64)
            return "x86_64"
        #elseif arch(i386)
            return "i386"
        #else
            return "unknown"
        #endif
    }
}
