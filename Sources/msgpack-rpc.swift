//
//  msgpack-rpc.swift
//
//
//  Created by David Buchan-Swanson on 23/3/2024.
//

import Foundation
import MessagePack
import Socket

class MsgPackRPC {
    let socketDescriptor: Int32;
    let encoder = MessagePackEncoder()
    let decoder = MessagePackDecoder()

    enum SocketError: Error {
        case notAvailable
        case unableToSend
    }

    typealias SockAddr = sockaddr.Type;

    init(socketPath: URL) throws {
        var address = sockaddr_un();
        address.sun_family = sa_family_t(AF_UNIX)

        _ = socketPath.path.withCString {
            strncpy(&address.sun_path, $0, MemoryLayout.size(ofValue: address.sun_path))
        }

        let socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard socketDescriptor >= 0 else {
            print("Error creating socket: \(String(cString: strerror(errno)))")
            throw SocketError.notAvailable
        }

        // Connect to the Unix domain socket
        let connectResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { addressPointer in
                connect(socketDescriptor, addressPointer, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard connectResult >= 0 else {
            close(socketDescriptor)
            print("Error connecting to socket: \(String(cString: strerror(errno)))")
            throw SocketError.notAvailable
        }

        self.socketDescriptor = socketDescriptor;
    }

    deinit {
        close(socketDescriptor)
    }

    func send(method: String, params: [Codable]) throws -> Response {
        let req = Request(msgId: arc4random_uniform(UInt32.max), method: method, params: params)

        let messageBytes = try encoder.encode(req)

        let res = try request(data: messageBytes)

        let decoded = try decoder.decode(Response.self, from: res)

        #if DEBUG
            print("Decoded: \(decoded)")
        #endif
        return decoded
    }

    private func request(data: Data) throws -> Data {
        let bytesSent = data.withUnsafeBytes { bufferPointer in
            #if DEBUG
                print("--- DEBUG BYTES ---")
                print("[", terminator: "")
                for byte in bufferPointer {
                    print("\(byte)", terminator: ",")
                }
                print("]", terminator: "")
            #endif
            return Darwin.send(socketDescriptor, bufferPointer.baseAddress, bufferPointer.count, 0)
        }

        guard bytesSent >= 0 else {
            close(socketDescriptor)
            print("Error sending data: \(String(cString: strerror(errno)))")
            throw SocketError.unableToSend
        }

        return receive()
    }

    private func receive() -> Data {
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = recv(socketDescriptor, &buffer, buffer.count, 0)

        if bytesRead < 0 {
            return Data()
        }

        return Data(bytes: buffer, count: bytesRead)
    }
}

private struct Request: Codable {
    let msgId: UInt32
    let method: String
    let params: [any Codable]

    init(msgId: UInt32, method: String, params: [any Codable]) {
        self.msgId = msgId
        self.method = method
        self.params = params
    }

    init(from decoder: Decoder) throws {
        // this one doesn't get decoded
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Decoding not supported"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(0) // 0 is REQUEST
        try container.encode(self.msgId)
        try container.encode(self.method)
        var nested = container.nestedUnkeyedContainer()
        try self.params.forEach{ try nested.encode($0) }
    }
}

struct Response: Codable {
    let msgId: UInt32
    let error: Data?
    let result: Data?

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(UInt8.self) // the type
        self.msgId = try container.decode(UInt32.self)
        self.error = try container.decodeIfPresent(Data.self)
        self.result = try container.decodeIfPresent(Data.self)
    }

    func encode(to encoder: Encoder) throws {
        // this one doesn't get encoded
        throw EncodingError.invalidValue("", EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported"))
    }
}
