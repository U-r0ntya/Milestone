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
            case .needsOnboarding:
                OnboardingView(authViewModel: authViewModel)  // 初回設定
            case .signedIn(let user):
                MainTabView(authViewModel: authViewModel, user: user)
            }
        }
        .task {  // 画面が出たときに起動時チェックを呼ぶ
            await authViewModel.checkCurrentUser()
        }
    }
}
