import Darwin
import Foundation
import MachO
import UIKit

enum JailBrokenHelper {
  // MARK: - Direct Checks

  static func hasCydiaInstalled() -> Bool {
    guard let cydiaURL = URL(string: "cydia://"),
          let sileoURL = URL(string: "sileo://"),
          let zbraURL = URL(string: "zbra://")
    else { return false }
    return UIApplication.shared.canOpenURL(cydiaURL)
      || UIApplication.shared.canOpenURL(sileoURL)
      || UIApplication.shared.canOpenURL(zbraURL)
  }

  static func isContainsSuspiciousApps() -> Bool {
    for path in suspiciousAppsPathToCheck where FileManager.default.fileExists(atPath: path) {
      return true
    }
    return false
  }

  static func isSuspiciousSystemPathsExists() -> Bool {
    for path in suspiciousSystemPathsToCheck where FileManager.default.fileExists(atPath: path) {
      return true
    }
    return false
  }

  // MARK: - Advanced Checks

  static func canEditSystemFiles() -> Bool {
    let attempts = [
      (contents: "Developer Insider", path: "/private/Developer Insider"),
      (contents: "sandbox_test", path: "/private/sandbox_test")
    ]

    for attempt in attempts {
      do {
        try attempt.contents.write(toFile: attempt.path, atomically: true, encoding: .utf8)
        try FileManager.default.removeItem(atPath: attempt.path)
        return true
      } catch {
        continue
      }
    }
    return false
  }

  static func hasSuspiciousSymlinks() -> Bool {
    let paths = ["/Applications", "/Library", "/usr/lib", "/bin", "/etc", "/var"]
    let knownSafeSymlinks: [String: (String) -> Bool] = [
      "/bin": { destination in destination.hasSuffix("/private/bin") || destination == "private/bin" },
      "/etc": { destination in destination.hasSuffix("/private/etc") || destination == "private/etc" },
      "/tmp": { destination in destination.hasSuffix("/private/tmp") || destination == "private/tmp" },
      "/var": { destination in destination.hasSuffix("/private/var") || destination == "private/var" }
    ]

    for path in paths {
      do {
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        guard attributes[.type] as? FileAttributeType == .typeSymbolicLink else {
          continue
        }

        if let isKnownSafe = knownSafeSymlinks[path] {
          let destination = try FileManager.default.destinationOfSymbolicLink(atPath: path)
          if isKnownSafe(destination) {
            continue
          }
        }

        return true
      } catch {
        continue
      }
    }
    return false
  }

  // Checks for suspicious dylibs
  static func checkDYLD() -> Bool {
    let suspiciousLibraries = [
      "SubstrateLoader.dylib",
      "libhooker.dylib",
      "SubstrateBootstrap.dylib",
      "libsubstitute.dylib",
      "libellekit.dylib"
    ]

    for index in 0..<_dyld_image_count() {
      guard let cName = _dyld_get_image_name(index) else { continue }
      let imagePath = String(cString: cName)
      if suspiciousLibraries.contains(where: { imagePath.localizedCaseInsensitiveContains($0) }) {
        return true
      }
    }

    let fileManager = FileManager.default
    for library in suspiciousLibraries
      where fileManager.fileExists(atPath: "/usr/lib/\(library)")
      || fileManager.fileExists(atPath: "/Library/MobileSubstrate/DynamicLibraries/\(library)") {
      return true
    }

    return false
  }

  // MARK: - Path Lists (same as previous version)

  private static var suspiciousAppsPathToCheck: [String] {
    [
      // Traditional jailbreaks
      "/Applications/Cydia.app",
      "/Applications/blackra1n.app",
      "/Applications/FakeCarrier.app",
      "/Applications/Icy.app",
      "/Applications/IntelliScreen.app",
      "/Applications/MxTube.app",
      "/Applications/RockApp.app",
      "/Applications/SBSettings.app",
      "/Applications/WinterBoard.app",

      // Modern jailbreaks
      "/Applications/Palera1n.app",
      "/Applications/Sileo.app",
      "/Applications/Zebra.app",
      "/Applications/TrollStore.app",
      "/var/containers/Bundle/Application/TrollStore.app",

      // Checkra1n
      "/Applications/checkra1n.app",

      // Rootless jailbreak paths
      "/var/jb/Applications/Cydia.app",
      "/var/jb/Applications/Sileo.app",
      "/var/jb/Applications/Zebra.app"
    ]
  }

  private static var suspiciousSystemPathsToCheck: [String] {
    [
      // Traditional paths
      "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
      "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
      "/private/var/lib/apt",
      "/private/var/lib/cydia",
      "/private/var/mobile/Library/SBSettings/Themes",
      "/private/var/stash",
      "/private/var/tmp/cydia.log",
      "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
      "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
      "/usr/bin/sshd",
      "/usr/libexec/sftp-server",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/bin/bash",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",

      // Modern jailbreak paths
      "/var/jb", // Rootless jailbreak root
      "/var/binpack", // Checkm8 jailbreak
      "/var/containers/Bundle/tweaksupport",
      "/var/mobile/Library/palera1n",
      "/var/mobile/Library/xyz.willy.Zebra",
      "/var/lib/undecimus",

      // Palera1n specific
      "/var/jb/basebin",
      "/var/jb/usr",
      "/var/jb/etc",
      "/var/jb/Library",
      "/var/jb/.installed_palera1n",
      "/var/binpack/Applications",
      "/var/binpack/usr",

      // TrollStore
      "/var/containers/Bundle/Application/trollstorehelper",
      "/var/containers/Bundle/trollstore",

      // Bootstrap files
      "/var/jb/preboot",
      "/var/jb/var"
    ]
  }
}
