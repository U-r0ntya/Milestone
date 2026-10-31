import GoogleSignInSwift
import SwiftUI

struct RootView: View {
    @State private var authViewModel = AuthViewModel()  // ViewModel を持つ

    // 初回設定の仮画面の入力（仮）
    @State private var name = ""
    @State private var bio = ""
    @State private var device: Device = .nintendoSwitch

    var body: some View {
        VStack(spacing: 16) {
            switch authViewModel.state {
            case .checking:
                // くるくるを出す
                ProgressView()
            case .signedOut:
                LoginView(authViewModel: authViewModel)
            case .needsOnboarding:
                // Picker、名前と自己紹介の TextField、完了ボタン
                TextField("名前(必須)", text: $name)
                TextField("自己紹介文", text: $bio)
                Picker("機種（必須）", selection: $device) {
                    ForEach(Device.allCases, id: \.self) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                Button("完了") {
                    Task {
                        await authViewModel.completeOnboarding(
                            name: name,
                            device: device,
                            bio: bio == "" ? nil : bio
                        )
                    }
                }
                .disabled(name.isEmpty)

            case .signedIn(let user):
                // 名前を表示して、ログアウトボタンを置く
                Text(user.name)
                Button("ログアウト") {
                    authViewModel.signOut()

                }
            }
        }
        .padding()
        .task {  // 画面が出たときに起動時チェックを呼ぶ
            await authViewModel.checkCurrentUser()
        }
    }
}
