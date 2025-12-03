//
//  WebRTCMultiService.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 03.12.2025.
//

import Foundation
import WebRTC

protocol WebRTCService {
    var events: AsyncStream<WebRTCEvent> { get }
    var localVideoTrack: RTCVideoTrack? { get }
    
    func createOffer() async throws -> SessionDescription
    func createAnswer() async throws -> SessionDescription
    func setRemoteDescription(_ sdp: SessionDescription) async throws
    func addIceCandidate(_ candidate: IceCandidate) async throws
    func startCapture()
    func close()
}
