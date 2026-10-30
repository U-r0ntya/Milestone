import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct MilestoneApp: App {
    init() {
        // アプリが起動したときに Firebase を使える状態にする
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // Google のログイン画面からアプリに戻ってきたときの処理
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
