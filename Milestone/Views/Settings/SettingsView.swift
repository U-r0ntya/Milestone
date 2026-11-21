import SwiftUI

// プロフィール（フェーズ7で作る）
struct SettingsView: View {
    let authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("＜") { dismiss() }
                }
            }

        }
    }
}

#Preview {
    SettingsView(authViewModel: AuthViewModel(repository: MockUserRepository()))
}
