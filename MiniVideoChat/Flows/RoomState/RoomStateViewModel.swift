//
//  RoomStateViewModel.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 03.12.2025.
//

import Foundation
import Combine

@MainActor
final class RoomStateViewModel: ObservableObject {
    
    @Published var isCaller: Bool = true
    @Published var connectionState: SocketConnectionState = .disconnected
    @Published var remotePeer: PeerUser?
    @Published var error: String?
    @Published var isLoading = false
    @Published var incomingOffer: String?
    
    let username: String
    let roomId: Int
    
    private let socketService: SocketService
    private let userSessionService: UserSessionService
    private let onJoinCall: (PeerUser?, Bool, String?) -> Void
    private let onLogout: () -> Void
    private var eventsTask: Task<Void, Never>?
    
    var isConnected: Bool {
        connectionState == .connected
    }
    
    var isPeerAvailable: Bool {
        guard let peer = remotePeer else { return false }
        return peer.isCaller != isCaller
    }
    
    var canStartCall: Bool {
        isConnected && isPeerAvailable
    }
    
    init(
        socketService: SocketService,
        userSessionService: UserSessionService,
        onJoinCall: @escaping (PeerUser?, Bool, String?) -> Void,
        onLogout: @escaping () -> Void
    ) {
        self.socketService = socketService
        self.userSessionService = userSessionService
        self.onJoinCall = onJoinCall
        self.onLogout = onLogout
        self.username = userSessionService.username ?? ""
        self.roomId = userSessionService.roomId ?? 0
    }
    
    deinit {
        eventsTask?.cancel()
    }
    
    func connect() {
        guard connectionState != .connected,
              connectionState != .connecting else {
            return
        }
        eventsTask?.cancel()
        connectionState = .connecting
        error = nil
        eventsTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await socketService.connect(
                    roomId: roomId,
                    username: username,
                    isCaller: isCaller
                )
                await MainActor.run {
                    self.connectionState = .connected
                }
                for await event in socketService.events() {
                    await self.handle(event)
                }
            } catch {
                await MainActor.run {
                    self.connectionState = .error(error.localizedDescription)
                    self.error = "Connection error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func disconnect() {
        eventsTask?.cancel()
        eventsTask = nil
        socketService.disconnect()
        connectionState = .disconnected
        remotePeer = nil
        incomingOffer = nil
    }
    
    func startCall() {
        guard let peer = remotePeer,
              canStartCall else {
            return
        }
        onJoinCall(peer, isCaller, nil)
    }
    
    func logout() {
        disconnect()
        userSessionService.clear()
        onLogout()
    }
}

private extension RoomStateViewModel {
    func handle(_ event: SocketEvent) async {
        await MainActor.run {
            switch event {
            case .connected:
                connectionState = .connected
                error = nil
            case .disconnected:
                connectionState = .disconnected
                remotePeer = nil
            case .error(let message):
                connectionState = .error(message)
                error = message
            case .userJoined(let user):
                remotePeer = PeerUser(
                    username: user.username,
                    roomId: roomId,
                    isCaller: user.isCaller
                )
            case .userLeft(let user):
                if remotePeer?.username == user.username {
                    remotePeer = nil
                }
            case .offer(let sdp):
                if !isCaller {
                    onJoinCall(nil, false, sdp)
                }
            case .answer, .candidate:
                break
            }
        }
    }
}
