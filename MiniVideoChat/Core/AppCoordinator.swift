//
//  AppCoordinator.swift
//  MiniVideoChat
//

import Stinsen
import SwiftUI
import Combine

@MainActor
final class AppCoordinator: NavigationCoordinatable {

    @Root var start = makeStart
    @Root var auth = makeAuthFlow
    @Root var roomFlow = makeRoomFlow

    let stack = NavigationStack(initial: \AppCoordinator.start)

    private let socketService: SocketService
    private let userSessionService: UserSessionService
    private let webRTCService: WebRTCService
    
    init(
        socketService: SocketService,
        userSessionService: UserSessionService,
        webRTCService: WebRTCService
    ) {
        self.socketService = socketService
        self.userSessionService = userSessionService
        self.webRTCService = webRTCService
    }

    @ViewBuilder
    func makeStart() -> some View {
        if (userSessionService.username != nil && userSessionService.roomId != nil) {
            makeRoomFlow()
        } else {
            makeAuthFlow()
        }
    }
    
    @ViewBuilder
    private func makeAuthFlow() -> some View {
        AuthCoordinator(
            userSessionService: userSessionService,
            onLoginSuccess: { [weak self] in
                self?.root(\.roomFlow)
            }
        ).view()
    }
    
    @ViewBuilder
    private func makeRoomFlow() -> some View {
        RoomStateCoordinator(
            socketService: socketService,
            userSessionService: userSessionService,
            webRTCService: webRTCService,
            onLogout: { [weak self] in
                self?.root(\.auth)
            }
        ).view()
    }
}
