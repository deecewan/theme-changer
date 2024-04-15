//
//  neovim-rpc.swift
//
//
//  Created by David Buchan-Swanson on 23/3/2024.
//

import Foundation



class NeovimRPC {
    lazy var sockets: [MsgPackRPC] = getSocketPaths().compactMap { try? MsgPackRPC(socketPath: $0) }

    private func getSocketPaths() -> [URL] {
        let path = ProcessInfo.processInfo.environment["TMPDIR"] ?? "/tmp"
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: path) else {
            print("Error: Unable to list files at path \(path)")
            return []
        }

        guard let nvimDir = files.first(where: { $0.starts(with: "nvim") }) else {
            print("Error: nvim directory not present")
            return []
        }

        let absoluteNvimDir = "\(path)/\(nvimDir)"

        guard let enumerator = FileManager.default.enumerator(at: URL(filePath: absoluteNvimDir), includingPropertiesForKeys: [.typeIdentifierKey]) else { return [] }

        let sockets: [URL] = enumerator.compactMap {
            guard let url = $0 as? URL else { return nil }
            guard let resourceValues = try? url.resourceValues(forKeys: [.typeIdentifierKey]) else { return nil }
            if let fileType = resourceValues.typeIdentifier, fileType == "public.socket" {
                return url
            }
            return nil
        }

        return sockets
    }

    func set_option_value(name: String, value: Codable) {
        let params: [Codable] = [name, value, EmptyOpts()]
        for socket in sockets {
            do {
                let _ = try socket.send(method: "nvim_set_option_value", params: params)
            } catch {
                print("error: \(error)")
            }
        }
    }
}

struct EmptyOpts : Codable {

}
