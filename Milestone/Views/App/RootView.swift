import SwiftUI

struct RootView: View {
    @State private var authViewModel = AuthViewModel()  // ViewModel を持つ
    var body: some View {
        VStack(spacing: 16) {
            switch authViewModel.state {
            case .checking:
                // くるくるを出す
                ProgressView()
            case .signedOut:
                LoginView(authViewModel: authViewModel)  // ログイン画面
            case .signedIn(let user):
                MainView(authViewModel: authViewModel, user: user)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)  // 画面全体の背景（ライトは白、ダークはくすんだ紫）
        .task {  // 画面が出たときに起動時チェックを呼ぶ
            await authViewModel.checkCurrentUser()
        }
    }
}
