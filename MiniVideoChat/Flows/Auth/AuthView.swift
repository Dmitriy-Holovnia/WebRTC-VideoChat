import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        Form {
            fieldsSection
    
            errorSection
            
            сontinueSection
        }
        .navigationTitle("Mini Video Chat")
    }
    
    private var fieldsSection: some View {
        Section {
            TextField("Username", text: $viewModel.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            TextField("Room ID", text: $viewModel.roomId)
                .keyboardType(.numberPad)
        }
    }
    
    private var errorSection: some View {
        Section {
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .transition(.slide)
            } else {
                EmptyView()
            }
        }
    }
    
    private var сontinueSection: some View {
        Section {
            Button("Continue") {
                viewModel.login()
            }
            .frame(maxWidth: .infinity)
            .disabled(viewModel.isLoading)
        }
    }
}
