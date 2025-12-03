//
//  MiniVideoChatApp.swift
//  MiniVideoChat
//

import SwiftUI
import Stinsen

@main
struct MiniVideoChatApp: App {

    private let socketService: SocketService = SocketIOService()
    private let userSessionService: UserSessionService = UserDefaultsService()
    private let webRTCService: WebRTCService = WebRTCMultiService()
    
    var body: some Scene {
        WindowGroup {
            AppCoordinator(
                socketService: socketService,
                userSessionService: userSessionService,
                webRTCService: webRTCService
            ).view()
        }
    }
}
