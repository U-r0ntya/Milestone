import SwiftUI

// ログイン後のメイン画面：タイムライン／ワールド／プロフィールの3つのタブ
struct MainView: View {
    let authViewModel: AuthViewModel
    let user: User  // ログイン中の人
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            WorldListView(user: user)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isShowingSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape")
                        }.accessibilityLabel("設定")
                    }
                }
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView(authViewModel: authViewModel)
                }
                .accessibilityLabel("閉じる")
        }
    }
}

#Preview {
    MainView(
        authViewModel: AuthViewModel(repository: MockUserRepository()),
        user: User(id: "preview", name: "taiki")
    )
}
