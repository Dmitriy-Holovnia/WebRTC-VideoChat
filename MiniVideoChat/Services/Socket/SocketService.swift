//
//  SocketService.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 04.12.2025.
//

import Foundation

protocol SocketService {
    func connect(roomId: Int, username: String, isCaller: Bool) async throws
    func disconnect()
    func events() -> AsyncStream<SocketEvent>

    func sendOffer(sdp: String) async
    func sendAnswer(sdp: String) async
    func sendCandidate(candidate: String, sdpMid: String?, sdpMLineIndex: Int32) async
}
