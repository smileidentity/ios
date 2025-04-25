import Foundation
import os.log

/**
 * Utility class for benchmarking execution time and measuring file sizes.
 * currently heavily borrows from android can be refined to feel more iosy :joy
 */
class BenchMarkUtils {
    /**
     * Measures the size of a file.
     *
     * @param filePath The path to the file
     * @return The size of the file in bytes, or -1 if the file doesn't exist
     */
    static func measureFileSize(filePath: String) -> Int64 {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: filePath) {
            os_log("File does not exist: %@", log: .default, type: .error, filePath)
            return -1
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            if let size = attributes[FileAttributeKey.size] as? Int64 {
                os_log("File size (%@): %@", log: .default,
                       type: .debug, filePath, formatSize(bytes: size))
                return size
            }
        } catch {
            os_log("Error getting file size: %@", log: .default,
                   type: .error, error.localizedDescription)
        }

        return -1
    }

    /**
     * Formats a byte size into a human-readable string (KB, MB, etc.)
     *
     * @param bytes The size in bytes
     * @return A formatted string representation of the size
     */
    static func formatSize(bytes: Int64) -> String {
        switch bytes {
        case 0 ..< 1024:
            return "\(bytes) bytes"
        case 1024 ..< (1024 * 1024):
            return String(format: "%.2f KB", Double(bytes) / 1024.0)
        case (1024 * 1024) ..< (1024 * 1024 * 1024):
            return String(format: "%.2f MB", Double(bytes) / (1024.0 * 1024.0))
        default:
            return String(format: "%.2f GB", Double(bytes) / (1024.0 * 1024.0 * 1024.0))
        }
    }

    /**
     * Creates a comprehensive benchmark session that can track both time and size metrics.
     *
     * @param operationName The name of the operation being benchmarked
     * @return A BenchmarkSession instance
     */
    static func createSession(operationName: String) -> BenchmarkSession {
        return BenchmarkSession(operationName: operationName)
    }

    /**
     * A class for tracking comprehensive benchmarks including time and size metrics.
     */
    class BenchmarkSession {
        private let operationName: String
        private let startTime: TimeInterval
        private var lastLapTime: TimeInterval
        private var lapCount: Int = 0
        private var metrics: [String: String] = [:]

        init(operationName: String) {
            self.operationName = operationName
            startTime = Date().timeIntervalSince1970 * 1000
            lastLapTime = startTime
        }

        /**
         * Logs the time elapsed since the last lap (or start if no laps yet).
         *
         * @param lapName Optional name for this timing point
         * @return This BenchmarkSession instance for chaining
         */
        @discardableResult
        func lap(lapName: String? = nil) -> BenchmarkSession {
            lapCount += 1
            let name = lapName ?? "Step \(lapCount)"
            let currentTime = Date().timeIntervalSince1970 * 1000
            let lapTime = currentTime - lastLapTime
            let totalTime = currentTime - startTime

            os_log("%@ - %@: %.0f ms (Total: %.0f ms)", log: .default,
                   type: .debug, operationName, name, lapTime, totalTime)
            metrics["\(name) Time"] = "\(Int(lapTime)) ms"
            lastLapTime = currentTime
            return self
        }

        /**
         * Records a file size metric.
         *
         * @param name Name of the metric
         * @param filePath The path to the file
         * @return This BenchmarkSession instance for chaining
         */
        @discardableResult
        func recordFileSize(name: String, filePath: String) -> BenchmarkSession {
            let size = BenchMarkUtils.measureFileSize(filePath: filePath)
            if size >= 0 {
                metrics["\(name) Size"] = BenchMarkUtils.formatSize(bytes: size)
            }
            return self
        }

        /**
         * Logs the total time elapsed and all recorded metrics, then finishes the benchmark session.
         *
         * @param finalMessage Optional final message
         * @return A map of all recorded metrics
         */
        func stop(finalMessage: String = "completed") -> [String: String] {
            let totalTime = Date().timeIntervalSince1970 * 1000 - startTime
            metrics["Total Time"] = "\(Int(totalTime)) ms"

            os_log("=== %@ %@ in %.0f ms ===", log: .default, type: .debug,
                   operationName, finalMessage, totalTime)
            os_log("=== Benchmark Summary ===", log: .default, type: .debug)

            for (key, value) in metrics {
                os_log("%@: %@", log: .default, type: .debug, key, value)
            }

            os_log("=== End of Benchmark ===", log: .default, type: .debug)

            return metrics
        }
    }
}
