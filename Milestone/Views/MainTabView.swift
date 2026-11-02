import SwiftUI

// ログイン後のメイン画面：タイムライン／ワールド／プロフィールの3つのタブ
struct MainTabView: View {
    let authViewModel: AuthViewModel
    let user: User  // ログイン中の人

    var body: some View {
        TabView {
            // タイムライン
            NavigationStack {
                TimelineView(user: user)  // ログイン中の人を渡す（投稿に使う）
                    .appHeader("タイムライン")
            }
            .tabItem {
                Label("タイムライン", systemImage: "text.bubble")
            }

            // ワールド
            NavigationStack {
                WorldView()
                    .appHeader("ワールド")
            }
            .tabItem {
                Label("ワールド", systemImage: "cube")
            }

            // プロフィール
            NavigationStack {
                ProfileView(authViewModel: authViewModel, user: user)
                    .appHeader("プロフィール")
            }
            .tabItem {
                Label("プロフィール", systemImage: "person")
            }
        }
    }
}
