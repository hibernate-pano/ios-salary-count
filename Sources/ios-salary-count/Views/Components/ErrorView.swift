import SwiftUI

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: retryAction) {
                Text("重试")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 120, height: 40)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ErrorAlert: ViewModifier {
    let error: Error?
    let dismissAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("错误", isPresented: .constant(error != nil)) {
                Button("确定", role: .cancel) {
                    dismissAction()
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    func errorAlert(error: Error?, dismissAction: @escaping () -> Void) -> some View {
        modifier(ErrorAlert(error: error, dismissAction: dismissAction))
    }
}

#Preview {
    ErrorView(
        error: NSError(domain: "com.example", code: -1, userInfo: [NSLocalizedDescriptionKey: "网络连接失败，请检查网络设置"]),
        retryAction: {}
    )
} 