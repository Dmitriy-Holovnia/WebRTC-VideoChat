//
//  WebRTCModels.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 04.12.2025.
//

import Foundation
import WebRTC

struct SessionDescription: Codable {
    let type: String
    let sdp: String
    
    init(type: String, sdp: String) {
        self.type = type
        self.sdp = sdp
    }
    
    init(from rtcSessionDescription: RTCSessionDescription) {
        self.sdp = rtcSessionDescription.sdp
        switch rtcSessionDescription.type {
        case .offer: self.type = "offer"
        case .answer: self.type = "answer"
        case .prAnswer: self.type = "pranswer"
        case .rollback: self.type = "rollback"
        @unknown default: self.type = "unknown"
        }
    }
    
    var rtcSessionDescription: RTCSessionDescription {
        let sdpType: RTCSdpType
        switch type {
        case "offer": sdpType = .offer
        case "answer": sdpType = .answer
        case "pranswer": sdpType = .prAnswer
        case "rollback": sdpType = .rollback
        default: sdpType = .offer
        }
        return RTCSessionDescription(type: sdpType, sdp: sdp)
    }
}

struct IceCandidate: Codable {
    let candidate: String
    let sdpMid: String?
    let sdpMLineIndex: Int32
    
    init(candidate: String, sdpMid: String?, sdpMLineIndex: Int32) {
        self.candidate = candidate
        self.sdpMid = sdpMid
        self.sdpMLineIndex = sdpMLineIndex
    }
    
    init(from rtcIceCandidate: RTCIceCandidate) {
        self.candidate = rtcIceCandidate.sdp
        self.sdpMid = rtcIceCandidate.sdpMid
        self.sdpMLineIndex = rtcIceCandidate.sdpMLineIndex
    }
    
    var rtcIceCandidate: RTCIceCandidate {
        RTCIceCandidate(sdp: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
}

enum WebRTCEvent {
    case didGenerateCandidate(IceCandidate)
    case connectionStateChanged(RTCIceConnectionState)
    case didReceiveRemoteVideoTrack(RTCVideoTrack)
}

enum WebRTCError: Error {
    case peerConnectionNotInitialized
    case sdpGenerationFailed
}
