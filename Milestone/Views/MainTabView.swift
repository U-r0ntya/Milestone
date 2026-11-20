import SwiftUI

// ログイン後のメイン画面：タイムライン／ワールド／プロフィールの3つのタブ
struct MainTabView: View {
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
    MainTabView(
        authViewModel: AuthViewModel(repository: MockUserRepository()),
        user: User(id: "preview", name: "たいき", iconURL: nil, device: .iPhone, bio: nil)
    )
}
