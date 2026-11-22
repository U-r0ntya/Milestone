import SwiftUI

struct RootView: View {
    @State private var authViewModel = AuthViewModel()  // ViewModel を持つ
    @State private var hasWaitedMinimum = false // 最低時間がたったかどうか
    var body: some View {
        VStack(spacing: 16) {
            // 1秒たつまでは、調べ終わっていてもロード画面のまま
            if !hasWaitedMinimum {
                loading
            } else {
                switch authViewModel.state {
                case .checking:
                    loading  // 1秒たっても、まだ調べているとき
                case .signedOut:
                    LoginView(authViewModel: authViewModel)  // ログイン画面
                        .transition(.opacity)
                case .signedIn(let user):
                    MainView(authViewModel: authViewModel, user: user)
                        .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.3), value: hasWaitedMinimum)
        .background(Color.appBackground)
        .task {  // 画面が出たときに起動時チェックを呼ぶ
            await authViewModel.checkCurrentUser()
        }
        .task {
            try? await Task.sleep(for: .seconds(1))
            hasWaitedMinimum = true
        }
    }

    // ロード画面（起動してから、前のログインが残っているか調べている間）
    // ログイン画面と同じ並べ方で、ロゴだけを見せる（切りかわってもロゴが動かない）
    private var loading: some View {
        LoginView(authViewModel: authViewModel, showsOnlyLogo: true)
            .transition(.opacity)
    }
}
