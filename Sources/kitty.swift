//
//  kitty.swift
//
//
//  Created by David Buchan-Swanson on 24/3/2024.
//

import Foundation

class Kitty {
    lazy var socket = getSocket()

    func setTheme(theme: Theme) {
        guard let socket = self.socket else {
            return // kitty not running
        }

        // TODO: make the theme file customizable
        let themeFile = "/Users/david/.config/kitty/tokyonight_\(theme == .dark ? "night" : "day").conf"

        let process = Process()
        process.launchPath = "/Applications/kitty.app/Contents/MacOS/kitten"
        process.arguments = ["@", "--to", "unix:\(socket)", "set-colors", "-ac", themeFile]
        process.launch()
    }

    // TODO: support multiple running processes? although kitty kinda just runs
    // one process, even if multiple windows are open, so yagni?
    private func getSocket() -> String? {
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", "lsof -U | grep 'kitty-' | awk '{print $8}'"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if let outputString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !outputString.isEmpty {
            return outputString
        }

        return nil
    }
}
