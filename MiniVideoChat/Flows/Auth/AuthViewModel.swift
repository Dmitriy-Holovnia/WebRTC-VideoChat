//
//  AuthViewModel.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 03.12.2025.
//

import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var username: String = ""
    @Published var roomId: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let userSessionService: UserSessionService
    private let onLoginSuccess: () -> Void

    init(
        userSessionService: UserSessionService,
        onLoginSuccess: @escaping () -> Void
    ) {
        self.userSessionService = userSessionService
        self.onLoginSuccess = onLoginSuccess
        loadSavedData()
    }

    func login() {
        errorMessage = nil
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Enter username"
            return
        }
        guard let roomIdInt = Int(roomId), roomIdInt > 0 else {
            errorMessage = "Enter correct Room ID (number)"
            return
        }
        userSessionService.save(username: username.trimmingCharacters(in: .whitespaces), roomId: roomIdInt)
        onLoginSuccess()
    }
}

private extension AuthViewModel {
    func loadSavedData() {
        if let savedUsername = userSessionService.username {
            username = savedUsername
        }
        if let savedRoomId = userSessionService.roomId {
            roomId = String(savedRoomId)
        }
    }
}
