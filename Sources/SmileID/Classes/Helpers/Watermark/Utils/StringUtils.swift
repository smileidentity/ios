import Foundation

class StringUtils {
    /** Note: For native methods to match android implementation we
     can have this in objective C for benchmarking but  starting to feel this
     is overkill given it's a spike and the benchmarks for swift aren't as bad so if needed
     can port android c++ code to objective C actually easier on ios
     */

    /**
     * Converts a string to its binary representation.
     * Each character in the input string is converted to an 8-bit binary string.
     *
     * @param inputText The string to convert
     * @return A string containing the binary representation of the input, or nil if the input is nil
     */
    static func stringToBinary(_ inputText: String?) -> String? {
        // Call the native implementation if available
        // For now, we'll use the Swift implementation
        return nonNativeStringToBinary(inputText)
    }

    /**
     * String to integer array.
     *
     * @param inputString The binary string to convert
     * @return An integer array with each element being the numeric value of the corresponding character
     */
    static func stringToIntArray(_ inputString: String?) -> [Int]? {
        // Call the native implementation if available
        // For now, we'll use the Swift implementation
        return nonNativeStringToIntArray(inputString)
    }

    /**
     * Converting a binary string to a ASCII string.
     */
    static func binaryToString(_ inputText: String?) -> String? {
        // Call the native implementation if available
        // For now, we'll use the Swift implementation
        return nonNativeBinaryToString(inputText)
    }

    /**
     * get the single digit number and set it to the target one.
     */
    static func replaceSingleDigit(target: Int, singleDigit: Int) -> Int {
        return (target / 10) * 10 + singleDigit
    }

    /**
     * Converts a string to an array of integers by interpreting each character as a digit.
     * Each character's numeric value is calculated by subtracting the ASCII value of '0'.
     *
     * @param inputString The string to convert
     * @return An integer array with each element being the numeric value of the corresponding character
     */
    static func nonNativeStringToIntArray(_ inputString: String?) -> [Int]? {
        // Return nil if input is nil
        guard let inputString = inputString else { return nil }

        // Create an integer array with the same length as the input string
        return inputString.map { Int($0.asciiValue! - Character("0").asciiValue!) }
    }

    /**
     * Converts a string to its binary representation.
     * Each character in the input string is converted to an 8-bit binary string.
     *
     * @param inputText The string to convert
     * @return A string containing the binary representation of the input, or nil if the input is nil
     */
    static func nonNativeStringToBinary(_ inputText: String?) -> String? {
        guard let inputText = inputText else {
            return nil
        }

        var result = ""

        for char in inputText {
            // Convert each character to its 8-bit binary representation
            let asciiValue = Int(char.asciiValue!)
            let binaryChar = String(asciiValue, radix: 2)

            // Ensure each binary representation is 8 bits by padding with leading zeros if needed
            let paddedBinary = binaryChar.padLeft(toLength: 8, withPad: "0")

            result += paddedBinary
        }

        return result
    }

    /**
     * Converts a binary string back to a regular text string.
     * Each 8 bits in the binary string are interpreted as a character.
     *
     * @param inputText The binary string to convert
     * @return The text string representation of the binary input, or nil if the input is nil
     */
    static func nonNativeBinaryToString(_ inputText: String?) -> String? {
        guard let inputText = inputText else {
            return nil
        }

        var result = ""
        var index = 0

        // Process the binary string in 8-bit chunks
        while index + 8 <= inputText.count {
            // Take the next 8 bits
            let startIndex = inputText.index(inputText.startIndex, offsetBy: index)
            let endIndex = inputText.index(inputText.startIndex, offsetBy: index + 8)
            let byte = String(inputText[startIndex ..< endIndex])

            // Convert the 8-bit binary string to an integer
            if let decimal = Int(byte, radix: 2) {
                // Convert the integer to a character and append it
                result.append(Character(UnicodeScalar(decimal)!))
            }

            // Move to the next 8 bits
            index += 8
        }

        return result
    }
}

// Extension to add padLeft functionality to String
extension String {
    func padLeft(toLength length: Int, withPad pad: String) -> String {
        if count >= length {
            return self
        }

        let padding = String(repeating: pad, count: length - count)
        return padding + self
    }
}
