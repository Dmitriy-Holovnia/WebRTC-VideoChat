import SwiftUI
import WebRTC

struct VideoChatView: View {
    @StateObject private var viewModel: VideoChatViewModel
    
    init(viewModel: VideoChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let track = viewModel.remoteVideoTrack {
                RTCVideoViewRepresentable(videoTrack: track)
                    .ignoresSafeArea()
            } else {
                previewVideoView
            }
            
            VStack {
                statusView
                
                Spacer()
                
                videoView
                
                endCallButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.start()
        }
    }
    
    private var previewVideoView: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.3))
            
            Text(viewModel.connectionState)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private var statusView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.peerUsername)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(connectionColor)
                        .frame(width: 8, height: 8)
                    Text(viewModel.connectionState)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            Spacer()
        }
        .padding()
        .padding(.top, 44)
        .background(.black.opacity(0.5).gradient)
    }
    
    private var videoView: some View {
        HStack {
            Spacer()
            
            if let track = viewModel.localVideoTrack {
                RTCVideoViewRepresentable(videoTrack: track, mirror: true)
                    .frame(width: 120, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                    )
            }
        }
        .padding()
    }
    
    private var endCallButton: some View {
        Button {
            viewModel.endCall()
        } label: {
            Image(systemName: "phone.down.fill")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 70, height: 70)
                .background(.red, in: Circle())
        }
        .padding(.bottom, 50)
    }
    
    private var connectionColor: Color {
        if viewModel.connectionState.contains("Connected") {
            return .green
        } else if viewModel.connectionState.contains("Error") {
            return .red
        } else {
            return .orange
        }
    }
}
