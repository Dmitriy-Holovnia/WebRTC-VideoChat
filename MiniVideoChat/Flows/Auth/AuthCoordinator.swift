//
//  AuthCoordinator.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 03.12.2025.
//

import Stinsen
import SwiftUI
import Combine

@MainActor
final class AuthCoordinator: NavigationCoordinatable {
    
    @Root var login = makeLogin

    let stack = NavigationStack(initial: \AuthCoordinator.login)

    private let userSessionService: UserSessionService
    private let onLoginSuccess: () -> Void

    init(
        userSessionService: UserSessionService,
        onLoginSuccess: @escaping () -> Void
    ) {
        self.userSessionService = userSessionService
        self.onLoginSuccess = onLoginSuccess
    }

    @ViewBuilder
    private func makeLogin() -> some View {
        let viewModel = AuthViewModel(
            userSessionService: userSessionService,
            onLoginSuccess: onLoginSuccess
        )
        AuthView(viewModel: viewModel)
    }
}
