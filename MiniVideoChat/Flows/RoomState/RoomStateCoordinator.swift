//
//  RoomStateCoordinator.swift
//  MiniVideoChat
//

import Stinsen
import SwiftUI
import Combine

@MainActor
final class RoomStateCoordinator: NavigationCoordinatable {

    @Root var roomState = makeRoomState
    @Route(.fullScreen) var videoChat = makeVideoChat
    
    let stack = Stinsen.NavigationStack(initial: \RoomStateCoordinator.roomState)
    
    var selectedPeer: PeerUser?
    var currentUserIsCaller: Bool = true
    var pendingOffer: String?

    private let socketService: SocketService
    private let userSessionService: UserSessionService
    private let webRTCService: WebRTCService
    private let onLogout: () -> Void

    init(
        socketService: SocketService,
        userSessionService: UserSessionService,
        webRTCService: WebRTCService,
        onLogout: @escaping () -> Void
    ) {
        self.socketService = socketService
        self.userSessionService = userSessionService
        self.webRTCService = webRTCService
        self.onLogout = onLogout
    }

    @ViewBuilder
    func makeRoomState() -> some View {
        let viewModel = RoomStateViewModel(
            socketService: socketService,
            userSessionService: userSessionService,
            onJoinCall: { [weak self] peer, isCaller, pendingOffer in
                guard let self else { return }
                self.selectedPeer = peer
                self.currentUserIsCaller = isCaller
                self.pendingOffer = pendingOffer
                self.route(to: \.videoChat)
            },
            onLogout: { [weak self] in
                self?.onLogout()
            }
        )
        RoomStateView(viewModel: viewModel)
    }

    @ViewBuilder
    func makeVideoChat() -> some View {
        let peerUsername = selectedPeer?.username ?? "Unknown"
        let viewModel = VideoChatViewModel(
            webRTCService: webRTCService,
            socketService: socketService,
            peerUsername: peerUsername,
            isCaller: currentUserIsCaller,
            pendingOffer: pendingOffer,
            onEndCall: { [weak self] in
                self?.popLast()
            }
        )
        VideoChatView(viewModel: viewModel)
    }
}
