//
//  PeerUser.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 04.12.2025.
//

import Foundation

struct PeerUser: Equatable {
    let username: String
    let roomId: Int
    let isCaller: Bool
}
