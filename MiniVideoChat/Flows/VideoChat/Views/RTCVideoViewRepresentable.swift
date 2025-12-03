//
//  RTCVideoViewRepresentable.swift
//  MiniVideoChat
//
//  Created by DmitriyHolovnia on 03.12.2025.
//

import SwiftUI
import WebRTC

struct RTCVideoViewRepresentable: UIViewRepresentable {
    let videoTrack: RTCVideoTrack
    var mirror: Bool = false
    
    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView()
        view.videoContentMode = .scaleAspectFill
        view.clipsToBounds = true
        videoTrack.add(view)
        return view
    }
    
    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) { }
}
