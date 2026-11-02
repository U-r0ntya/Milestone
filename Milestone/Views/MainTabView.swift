import SwiftUI

// ログイン後のメイン画面：タイムライン／ワールド／プロフィールの3つのタブ
struct MainTabView: View {
    let authViewModel: AuthViewModel
    let user: User  // ログイン中の人

    @State private var isShowingDraftDialog = false  // 下書きのカードを出しているか
    @AppStorage("composeDraftText") private var draftText = ""  // 投稿の画面と同じ下書き

    var body: some View {
        TabView {
            // タイムライン
            NavigationStack {
                TimelineView(
                    user: user,
                    isShowingDraftDialog: $isShowingDraftDialog
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
            if isShowingDraftDialog {
                DraftSaveDialog(
                    onSave: {
                        isShowingDraftDialog = false  // 下書きはもう保存されているので、閉じるだけ
                    },
                    onDelete: {
                        draftText = ""  // 下書きを消す
                        isShowingDraftDialog = false
                    }
                )
            }
        }
    }
}
