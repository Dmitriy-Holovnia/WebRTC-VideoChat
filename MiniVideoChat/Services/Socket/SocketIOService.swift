//
//  SocketIOService.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 03.12.2025.
//

import Foundation
import SocketIO

final class SocketIOService: SocketService {
    
    private(set) var state: SocketConnectionState = .disconnected
    
    private let baseURL: URL
    private let continuationLock = NSLock()
    private var eventContinuations: [AsyncStream<SocketEvent>.Continuation] = []
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    #warning("Inset macbook address here")
    init() {
        #if targetEnvironment(simulator)
        self.baseURL = URL(string: "http://localhost:3000")!
        #else
        self.baseURL = URL(string: "http://192.168.0.106:3000")!
        #endif
    }
    
    func events() -> AsyncStream<SocketEvent> {
        AsyncStream { continuation in
            continuationLock.lock()
            eventContinuations.append(continuation)
            continuationLock.unlock()
        }
    }
    
    func connect(roomId: Int, username: String, isCaller: Bool) async throws {
        disconnect()
        state = .connecting
        let connectParams: [String: Any] = [
            "roomId": roomId,
            "username": username,
            "isCaller": isCaller
        ]
        let manager = SocketManager(
            socketURL: baseURL,
            config: [
                .log(true),
                .compress,
                .connectParams(connectParams)
            ]
        )
        let socket = manager.defaultSocket
        self.manager = manager
        self.socket = socket
        setupHandlers(socket: socket)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            socket.once(clientEvent: .connect) { [weak self] data, ack in
                guard let self else { return }
                self.state = .connected
                self.broadcast(.connected)
                continuation.resume()
            }
            socket.once(clientEvent: .error) { [weak self] data, ack in
                guard let self else { return }
                let message = (data.first as? String) ?? "Unknown socket error"
                self.state = .error(message)
                self.broadcast(.error(message))
                continuation.resume(throwing: SocketConnectError.failed(message))
            }
            socket.connect()
        }
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        
        state = .disconnected
        broadcast(.disconnected)
        finishAllStreams()
    }
    
    func sendOffer(sdp: String) async {
        let payload: [String: Any] = [
            "type": "offer",
            "sdp": sdp
        ]
        socket?.emit("offer", payload)
    }
    
    func sendAnswer(sdp: String) async {
        let payload: [String: Any] = [
            "type": "answer",
            "sdp": sdp
        ]
        socket?.emit("answer", payload)
    }
    
    func sendCandidate(candidate: String, sdpMid: String?, sdpMLineIndex: Int32) async {
        let payload: [String: Any] = [
            "candidate": candidate,
            "sdpMid": sdpMid as Any,
            "sdpMLineIndex": Int(sdpMLineIndex)
        ]
        socket?.emit("candidate", payload)
    }
}

private extension SocketIOService {

    func setupHandlers(socket: SocketIOClient) {
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            guard let self else { return }
            self.state = .disconnected
            self.broadcast(.disconnected)
        }
        socket.on(clientEvent: .error) { [weak self] data, ack in
            guard let self else { return }
            let message = (data.first as? String) ?? "Unknown socket error"
            self.state = .error(message)
            self.broadcast(.error(message))
        }

        socket.on("room_user_joined") { [weak self] data, ack in
            guard let self else { return }
            guard let raw = data.first as? [String: Any] else {
                print("[Socket] room_user_joined: unexpected payload \(data)")
                return
            }

            let user = self.parseRoomUser(from: raw)
            self.broadcast(.userJoined(user))
        }

        socket.on("room_user_left") { [weak self] data, ack in
            guard let self else { return }
            guard let raw = data.first as? [String: Any] else {
                print("[Socket] room_user_left: unexpected payload \(data)")
                return
            }

            let user = self.parseRoomUser(from: raw)
            self.broadcast(.userLeft(user))
        }

        socket.on("offer") { [weak self] data, ack in
            guard let self else { return }
            guard let raw = data.first as? [String: Any],
                  let sdp = raw["sdp"] as? String else {
                print("[Socket] offer: unexpected payload \(data)")
                return
            }
            self.broadcast(.offer(sdp: sdp))
        }

        socket.on("answer") { [weak self] data, ack in
            guard let self else { return }
            guard let raw = data.first as? [String: Any],
                  let sdp = raw["sdp"] as? String else {
                print("[Socket] answer: unexpected payload \(data)")
                return
            }
            self.broadcast(.answer(sdp: sdp))
        }

        socket.on("candidate") { [weak self] data, ack in
            guard let self else { return }
            guard let raw = data.first as? [String: Any],
                  let candidate = raw["candidate"] as? String else {
                print("[Socket] candidate: unexpected payload \(data)")
                return
            }
            let sdpMid = raw["sdpMid"] as? String
            let sdpMLineIndex = (raw["sdpMLineIndex"] as? Int).map { Int32($0) } ?? 0
            self.broadcast(.candidate(
                candidate: candidate,
                sdpMid: sdpMid,
                sdpMLineIndex: sdpMLineIndex
            ))
        }
    }

    func parseRoomUser(from dict: [String: Any]) -> RoomUser {
        let username = dict["username"] as? String ?? "Unknown"
        let isCaller = dict["isCaller"] as? Bool ?? false
        return RoomUser(username: username, isCaller: isCaller)
    }

    func broadcast(_ event: SocketEvent) {
        continuationLock.lock()
        let continuations = eventContinuations
        continuationLock.unlock()
        for c in continuations {
            c.yield(event)
        }
    }

    func finishAllStreams() {
        continuationLock.lock()
        let continuations = eventContinuations
        eventContinuations.removeAll()
        continuationLock.unlock()
        continuations.forEach { $0.finish() }
    }
}
