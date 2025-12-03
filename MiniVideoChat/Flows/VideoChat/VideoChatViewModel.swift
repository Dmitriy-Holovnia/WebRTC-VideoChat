//
//  VideoChatViewModel.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 03.12.2025.
//

import Foundation
import Combine
import WebRTC

@MainActor
final class VideoChatViewModel: ObservableObject {
    
    @Published var connectionState: String = "Connecting..."
    @Published var remoteVideoTrack: RTCVideoTrack?
    @Published var isCallEnded = false
    
    let peerUsername: String
    let isCaller: Bool
    
    private let webRTCService: WebRTCService
    private let socketService: SocketService
    private let onEndCall: () -> Void
    private let pendingOffer: String?
    private var webRTCEventsTask: Task<Void, Never>?
    private var socketEventsTask: Task<Void, Never>?
    
    var localVideoTrack: RTCVideoTrack? {
        webRTCService.localVideoTrack
    }
    
    init(
        webRTCService: WebRTCService,
        socketService: SocketService,
        peerUsername: String,
        isCaller: Bool,
        pendingOffer: String? = nil,
        onEndCall: @escaping () -> Void
    ) {
        self.webRTCService = webRTCService
        self.socketService = socketService
        self.peerUsername = peerUsername
        self.isCaller = isCaller
        self.pendingOffer = pendingOffer
        self.onEndCall = onEndCall
    }
    
    deinit {
        webRTCEventsTask?.cancel()
        socketEventsTask?.cancel()
    }
    
    func start() {
        webRTCService.startCapture()
        startWebRTCEventsListener()
        startSocketEventsListener()
        if isCaller {
            startAsCaller()
        } else {
            if let offer = pendingOffer {
                handleRemoteOffer(sdp: offer)
            } else {
                connectionState = "Waiting for offer..."
            }
        }
    }
    
    func endCall() {
        cleanup()
        onEndCall()
    }
}
    
private extension VideoChatViewModel {
    func startAsCaller() {
        Task {
            do {
                connectionState = "Creating offer..."
                let offer = try await webRTCService.createOffer()
                connectionState = "Sending offer..."
                await socketService.sendOffer(sdp: offer.sdp)
                connectionState = "Waiting for answer..."
            } catch {
                connectionState = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    func startWebRTCEventsListener() {
        webRTCEventsTask = Task { [weak self] in
            guard let self else { return }
            for await event in webRTCService.events {
                await handleWebRTCEvent(event)
            }
        }
    }
    
    func startSocketEventsListener() {
        socketEventsTask = Task { [weak self] in
            guard let self else { return }
            for await event in socketService.events() {
                await handleSocketEvent(event)
            }
        }
    }
    
    func handleWebRTCEvent(_ event: WebRTCEvent) async {
        await MainActor.run {
            switch event {
            case .didGenerateCandidate(let candidate):
                Task {
                    await socketService.sendCandidate(
                        candidate: candidate.candidate,
                        sdpMid: candidate.sdpMid,
                        sdpMLineIndex: candidate.sdpMLineIndex
                    )
                }
            case .connectionStateChanged(let state):
                updateConnectionState(state)
            case .didReceiveRemoteVideoTrack(let track):
                remoteVideoTrack = track
            }
        }
    }
    
    func handleSocketEvent(_ event: SocketEvent) async {
        await MainActor.run {
            switch event {
            case .offer(let sdp):
                guard !isCaller else { return }
                handleRemoteOffer(sdp: sdp)
            case .answer(let sdp):
                guard isCaller else { return }
                handleRemoteAnswer(sdp: sdp)
            case .candidate(let candidate, let sdpMid, let sdpMLineIndex):
                handleRemoteCandidate(candidate: candidate, sdpMid: sdpMid, sdpMLineIndex: sdpMLineIndex)
            case .userLeft:
                connectionState = "Peer disconnected"
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await MainActor.run {
                        self.endCall()
                    }
                }
            case .connected, .disconnected, .error, .userJoined:
                break
            }
        }
    }
    
    func handleRemoteOffer(sdp: String) {
        Task {
            do {
                connectionState = "Offer received, connecting..."
                let sessionDescription = SessionDescription(type: "offer", sdp: sdp)
                try await webRTCService.setRemoteDescription(sessionDescription)
                connectionState = "Creating answer..."
                let answer = try await webRTCService.createAnswer()
                connectionState = "Sending answer..."
                await socketService.sendAnswer(sdp: answer.sdp)
                connectionState = "Connection..."
            } catch {
                connectionState = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    func handleRemoteAnswer(sdp: String) {
        Task {
            do {
                connectionState = "Answer received, setting up..."
                let sessionDescription = SessionDescription(type: "answer", sdp: sdp)
                try await webRTCService.setRemoteDescription(sessionDescription)
                connectionState = "Connection..."
            } catch {
                connectionState = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    func handleRemoteCandidate(candidate: String, sdpMid: String?, sdpMLineIndex: Int32) {
        Task {
            do {
                let iceCandidate = IceCandidate(
                    candidate: candidate,
                    sdpMid: sdpMid,
                    sdpMLineIndex: sdpMLineIndex
                )
                try await webRTCService.addIceCandidate(iceCandidate)
            } catch {
                debugPrint("Failed to add ICE candidate: \(error)")
            }
        }
    }
    
    func updateConnectionState(_ state: RTCIceConnectionState) {
        switch state {
        case .new:
            connectionState = "Initialization..."
        case .checking:
            connectionState = "Connection checking..."
        case .connected, .completed:
            connectionState = "Connected"
        case .failed:
            connectionState = "Connection error"
        case .disconnected:
            endCall()
        case .count, .closed:
            break
        @unknown default:
            break
        }
    }
    
    func cleanup() {
        webRTCEventsTask?.cancel()
        socketEventsTask?.cancel()
        webRTCService.close()
    }
}
