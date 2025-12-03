//
//  UserDefaultsService.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 03.12.2025.
//

import Foundation

protocol UserSessionService {
    var username: String? { get }
    var roomId: Int? { get }
    
    func save(username: String, roomId: Int)
    func clear()
}

final class UserDefaultsService: UserSessionService {
    
    private enum Keys {
        static let username = "com.minivideochat.username"
        static let roomId = "com.minivideochat.roomId"
    }
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    var username: String? {
        defaults.string(forKey: Keys.username)
    }
    
    var roomId: Int? {
        let value = defaults.integer(forKey: Keys.roomId)
        return value == 0 ? nil : value
    }
    
    func save(username: String, roomId: Int) {
        defaults.set(username, forKey: Keys.username)
        defaults.set(roomId, forKey: Keys.roomId)
    }
    
    func clear() {
        defaults.removeObject(forKey: Keys.username)
        defaults.removeObject(forKey: Keys.roomId)
    }
}

