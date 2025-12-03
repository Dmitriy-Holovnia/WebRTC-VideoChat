//
//  SocketIOModels.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 04.12.2025.
//

import Foundation

struct RoomUser: Equatable {
    let username: String
    let isCaller: Bool
}

enum SocketConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

enum SocketEvent {
    case connected
    case disconnected
    case error(String)
    
    case userJoined(RoomUser)
    case userLeft(RoomUser)
    
    case offer(sdp: String)
    case answer(sdp: String)
    case candidate(candidate: String, sdpMid: String?, sdpMLineIndex: Int32)
}

enum SocketConnectError: Error {
    case failed(String)
}
