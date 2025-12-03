//
//  RoomConnectionState.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 04.12.2025.
//

import Foundation

enum RoomConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}
