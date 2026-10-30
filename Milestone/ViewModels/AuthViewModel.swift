import FirebaseAuth
import SwiftUI

enum AuthState {
    case checking
    case signedOut
    case needsOnboarding
    case signedIn(User)
}

@Observable
@MainActor
final class AuthViewModel {

    var state: AuthState = .checking
    var errorMessage: String? = nil

    private let repository: UserRepository

    // 本番用：AuthViewModel() で作ると、本物（Firestore）へとつなぐ
    init() {
        self.repository = FirestoreUserRepository()
    }

    // テスト用：AuthViewModel(repository: 偽物) で作る
    init(repository: UserRepository) {
        self.repository = repository
    }

    // 起動時チェック：ログイン中の人がいるか確かめる
    func checkCurrentUser() async {
        // 1. ログイン中の人がいるか見る。いなければ、札を signedOut にして終わり
        guard let firebaseUser = Auth.auth().currentUser else {
            state = .signedOut
            return
        }
        // 2. いれば、その人の uid で loadUser を呼ぶ
        await loadUser(uid: firebaseUser.uid)
    }

    // uid の中身によって、stateを変更する
    private func loadUser(uid: String) async {
        do {
            // repositoryに uid の人を探してもらう。結果は User?（いれば User、いなければ nil）
            let user = try await repository.fetchUser(uid: uid)
            // userが、nil なら needsOnboarding、返ってきたら signedIn、
            guard let user else {
                state = .needsOnboarding
                return
            }
            state = .signedIn(user)
        } catch {
            // 失敗したら、伝言メモにメッセージを書いて、 signedOut にする
            errorMessage = "ユーザー情報を読み込めませんでした。通信状態を確かめて、もう一度試してください。"
            state = .signedOut
        }
    }

}
