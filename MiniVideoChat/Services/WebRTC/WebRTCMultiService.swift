//
//  WebRTCMultiService.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 04.12.2025.
//

import Foundation
import WebRTC
import AVFoundation

final class WebRTCMultiService: NSObject, WebRTCService {
    
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }()
    
    private let rtcAudioSession = RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")

    private var peerConnection: RTCPeerConnection?
    private var videoCapturer: RTCVideoCapturer?
    private var _localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var eventContinuation: AsyncStream<WebRTCEvent>.Continuation?
    
    private let mediaConstraints = RTCMediaConstraints(
        mandatoryConstraints: [
            kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
            kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue
        ],
        optionalConstraints: nil
    )
    
    private(set) lazy var events: AsyncStream<WebRTCEvent> = {
        AsyncStream { [weak self] continuation in
            self?.eventContinuation = continuation
        }
    }()
    
    var localVideoTrack: RTCVideoTrack? {
        _localVideoTrack
    }
        
    override init() {
        super.init()
        setupPeerConnection()
        configureAudioSession()
    }
    
    // MARK: - Public API
    
    func createOffer() async throws -> SessionDescription {
        guard let peerConnection else {
            throw WebRTCError.peerConnectionNotInitialized
        }
        return try await withCheckedThrowingContinuation { continuation in
            peerConnection.offer(for: mediaConstraints) { [weak self] sdp, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sdp else {
                    continuation.resume(throwing: WebRTCError.sdpGenerationFailed)
                    return
                }
                self?.peerConnection?.setLocalDescription(sdp) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: SessionDescription(from: sdp))
                    }
                }
            }
        }
    }
    
    func createAnswer() async throws -> SessionDescription {
        guard let peerConnection else {
            throw WebRTCError.peerConnectionNotInitialized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            peerConnection.answer(for: mediaConstraints) { [weak self] sdp, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sdp else {
                    continuation.resume(throwing: WebRTCError.sdpGenerationFailed)
                    return
                }
                self?.peerConnection?.setLocalDescription(sdp) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: SessionDescription(from: sdp))
                    }
                }
            }
        }
    }
    
    func setRemoteDescription(_ sdp: SessionDescription) async throws {
        guard let peerConnection else {
            throw WebRTCError.peerConnectionNotInitialized
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            peerConnection.setRemoteDescription(sdp.rtcSessionDescription) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func addIceCandidate(_ candidate: IceCandidate) async throws {
        guard let peerConnection else {
            throw WebRTCError.peerConnectionNotInitialized
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            peerConnection.add(candidate.rtcIceCandidate) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func startCapture() {
        #if targetEnvironment(simulator)
        startFileCapture()
        #else
        startCameraCapture()
        #endif
    }
    
    func close() {
        videoCapturer = nil
        _localVideoTrack = nil
        remoteVideoTrack = nil
        peerConnection?.close()
        peerConnection = nil
        eventContinuation?.finish()
    }
}



// MARK: - Private Methods

private extension WebRTCMultiService {
    
    func setupPeerConnection() {
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        ]
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
        )
        guard let peerConnection = Self.factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        ) else {
            return
        }
        self.peerConnection = peerConnection
        createMediaSenders()
    }
    
    func createMediaSenders() {
        let streamId = "stream"
        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = Self.factory.audioSource(with: audioConstraints)
        let audioTrack = Self.factory.audioTrack(with: audioSource, trackId: "audio0")
        peerConnection?.add(audioTrack, streamIds: [streamId])
        let videoSource = Self.factory.videoSource()
        
        #if targetEnvironment(simulator)
        videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        #else
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        #endif
        
        let videoTrack = Self.factory.videoTrack(with: videoSource, trackId: "video0")
        _localVideoTrack = videoTrack
        peerConnection?.add(videoTrack, streamIds: [streamId])
    }
    
    func configureAudioSession() {
        rtcAudioSession.lockForConfiguration()
        do {
            try rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat)
        } catch {
            debugPrint("Error configuring audio session: \(error)")
        }
        rtcAudioSession.unlockForConfiguration()
    }
    
    func startFileCapture() {
        guard let fileCapturer = videoCapturer as? RTCFileVideoCapturer else {
            debugPrint("[WebRTC] videoCapturer is not RTCFileVideoCapturer")
            return
        }
        fileCapturer.startCapturing(fromFileNamed: "webRtcTestVideo.mp4") { error in
            debugPrint("[WebRTC] Error starting file capture: \(error.localizedDescription)")
        }
    }
    
    func startCameraCapture() {
        guard let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer else { return }
        guard let frontCamera = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == .front }),
              let format = RTCCameraVideoCapturer.supportedFormats(for: frontCamera)
                .sorted(by: {
                    let width1 = CMVideoFormatDescriptionGetDimensions($0.formatDescription).width
                    let width2 = CMVideoFormatDescriptionGetDimensions($1.formatDescription).width
                    return width1 < width2
                }).last,
              let fps = format.videoSupportedFrameRateRanges
                .sorted(by: { $0.maxFrameRate < $1.maxFrameRate }).last
        else {
            return
        }
        cameraCapturer.startCapture(with: frontCamera, format: format, fps: Int(fps.maxFrameRate))
    }
}



// MARK: - RTCPeerConnectionDelegate

extension WebRTCMultiService: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("[WebRTC] Signaling state: \(stateChanged.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        debugPrint("[WebRTC] Did add stream")
        if let videoTrack = stream.videoTracks.first {
            remoteVideoTrack = videoTrack
            eventContinuation?.yield(.didReceiveRemoteVideoTrack(videoTrack))
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("[WebRTC] Did remove stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        debugPrint("[WebRTC] Should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("[WebRTC] ICE connection state: \(newState.rawValue)")
        eventContinuation?.yield(.connectionStateChanged(newState))
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("[WebRTC] ICE gathering state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let iceCandidate = IceCandidate(from: candidate)
        eventContinuation?.yield(.didGenerateCandidate(iceCandidate))
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("[WebRTC] Did remove candidates")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("[WebRTC] Did open data channel")
    }
}
