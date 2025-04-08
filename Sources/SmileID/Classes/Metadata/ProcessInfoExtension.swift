import Foundation

extension ProcessInfo {
    /// Returns the available physical memory in MB
    var availableMemoryInMB: String {
        // Get physical memory in bytes
        let physicalMemory = self.physicalMemory

        // Convert to MB (1 MB = 1048576 bytes)
        let memoryInMB = physicalMemory / 1048576

        return "\(memoryInMB)"
    }
}
