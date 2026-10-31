import SwiftUI

// ログイン後のメイン画面：タイムライン／ワールド／プロフィールの3つのタブ
struct MainTabView: View {
    let authViewModel: AuthViewModel
    let user: User   // ログイン中の人

    var body: some View {
        TabView {
            TimelineView()
                .tabItem {
                    Label("タイムライン", systemImage: "text.bubble")
                }
            WorldView()
                .tabItem {
                    Label("ワールド", systemImage: "cube")
                }
            ProfileView(authViewModel: authViewModel, user: user)
                .tabItem {
                    Label("プロフィール", systemImage: "person")
                }
        }
    }
}
