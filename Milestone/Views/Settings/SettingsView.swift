import SwiftUI

// プロフィール（フェーズ7で作る）
struct SettingsView: View {
    let authViewModel: AuthViewModel
    let user: User
    var body: some View {
        List {
            Section {
                Label {
                    Text(user.name).padding(.leading, 3)
                } icon: {
                    Image(systemName: "person")
                        .foregroundStyle(.primary)
                        .font(.system(size: 15))
                }
                Button(role: .destructive) {
                    authViewModel.signOut()
                } label: {
                    Label {
                        Text("ログアウト")
                    } icon: {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                            .foregroundStyle(Color.red)
                            .font(.system(size: 15))
                    }
                }.padding(.leading, 3)
            }
            Section {
                Text(
                    "このアプリは Minecraft の公式アプリではありません。\nMojang および Microsoft とは関係ありません。"
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
            authViewModel: AuthViewModel(repository: MockUserRepository()),
            user: User(id: "aaa", name: "taiki")
        )
    }
}
