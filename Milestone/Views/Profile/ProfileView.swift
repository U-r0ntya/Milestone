import SwiftUI

// プロフィール（フェーズ7で作る）
struct ProfileView: View {
    let authViewModel: AuthViewModel
    let user: User

    var body: some View {
        VStack {
            // 名前とログアウトボタン
            Text(user.name)
            Button("ログアウト") {
                authViewModel.signOut()
            }
        }
    }
}
#Preview {
    ProfileView(
        authViewModel: AuthViewModel(repository: PreviewUserRepository()),
        user: User(
            id: "preview",
            name: "すてぃーぶ",
            iconURL: nil,
            device: .iPhone,
            bio: nil
        )
    )
}
