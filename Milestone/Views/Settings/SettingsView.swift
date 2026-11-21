import SwiftUI

// プロフィール（フェーズ7で作る）
struct SettingsView: View {
    let authViewModel: AuthViewModel
    var body: some View {
        List {
            Section {
                Button("ログアウト", role: .destructive) {
                    authViewModel.signOut()
                }
            }
            Section {
                Text(
                    "このアプリは Minecraft の公式アプリではありません。Mojang および Microsoft とは関係ありません。"
                ).font(.footnote)
            }
        }
        .navigationTitle("設定")
        .toolbarRole(.editor)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            authViewModel: AuthViewModel(repository: MockUserRepository())
        )
    }
}
