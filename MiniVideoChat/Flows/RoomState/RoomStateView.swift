import SwiftUI

struct RoomStateView: View {
    @StateObject private var viewModel: RoomStateViewModel

    init(viewModel: RoomStateViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
            Form {
                userInfoSection
                
                roleSection
                
                peerSection
                
                controlSection
            }
            .navigationTitle("Room")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(connectionColor)
                            .frame(width: 8, height: 8)
                        Text(connectionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
    }
    
    private var userInfoSection: some View {
        Section("User Info") {
            LabeledContent("Username", value: viewModel.username)
            LabeledContent("Room ID", value: "\(viewModel.roomId)")
        }
    }
    
    private var roleSection: some View {
        Section("Role") {
            if viewModel.isConnected {
                LabeledContent("Role", value: viewModel.isCaller ? "Caller" : "Callee")
            } else {
                Toggle("Is Caller", isOn: $viewModel.isCaller)
            }
        }
    }
    
    private var peerSection: some View {
        Section("Peer Status") {
            if let peer = viewModel.remotePeer {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.green)
                    Text(peer.username)
                    Spacer()
                    Text(peer.isCaller ? "Caller" : "Callee")
                        .foregroundStyle(.secondary)
                }
                
                if viewModel.isPeerAvailable {
                    Label("Available", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Label(
                    viewModel.isConnected ? "Waiting for peer..." : "Connect to room first",
                    systemImage: "person.slash"
                )
                .foregroundStyle(.secondary)
            }
        }
    }
    
    private var errorSection: some View {
        Section {
            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
                    .transition(.slide)
            } else {
                EmptyView()
            }
        }
    }
    
    private var controlSection: some View {
        Section {
            Button("Start Call") {
                viewModel.startCall()
            }
            .disabled(!viewModel.canStartCall)
            
            Button(viewModel.isConnected ? "Disconnect" : "Connect") {
                if viewModel.isConnected {
                    viewModel.disconnect()
                } else {
                    viewModel.connect()
                }
            }
            
            Button("Logout", role: .destructive) {
                viewModel.logout()
            }
        }
    }
    
    private var connectionColor: Color {
        switch viewModel.connectionState {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .gray
        case .error: return .red
        }
    }
    
    private var connectionText: String {
        switch viewModel.connectionState {
        case .connected: return "Online"
        case .connecting: return "Connecting..."
        case .disconnected: return "Offline"
        case .error: return "Error"
        }
    }
}
