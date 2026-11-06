import SwiftUI

// ログイン後のメイン画面：タイムライン／ワールド／プロフィールの3つのタブ
struct MainTabView: View {
    let authViewModel: AuthViewModel
    let user: User  // ログイン中の人

    @State private var draftDialogKey: String? = nil // カードに出す下書きのキー（nil ならカードを出さない)


    var body: some View {
        TabView {
            // タイムライン
            NavigationStack {
                TimelineView(
                    user: user,
                    draftDialogKey: $draftDialogKey
                )  // ログイン中の人と、下書きのカードの値を渡す
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
        }.overlay {
            if let key = draftDialogKey {
                DraftSaveDialog(
                    onSave: {
                        draftDialogKey = nil // 入力ごとに下書きはもう保存されているので、閉じるだけ
                    },
                    onDelete: {
                        UserDefaults.standard.removeObject(forKey: key)
                        draftDialogKey = nil
                    }
                )
            }
        }
    }
}
