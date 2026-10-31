import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import SwiftUI

enum AuthState {
    case checking  // 確認中（起動直後。前のログインが残っているか調べている）
    case signedOut  // 未ログイン（ログイン画面を出す）
    case needsOnboarding  // ログイン済みだが、まだ初回設定をしていない（初回設定の画面を出す）
    case signedIn(User)  // 準備完了。User はログイン中の人の情報（ホーム画面を出す）
}

@Observable
@MainActor
final class AuthViewModel {

    var state: AuthState = .checking
    var errorMessage: String? = nil
    var isSaving = false   // 保存中かどうか

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
        // ログイン中の人がいるか見る。いなければ、signedOut にして終わり
        guard let firebaseUser = Auth.auth().currentUser else {
            state = .signedOut
            return
        }
        // いれば、その人の uid で loadUser を呼ぶ
        await loadUser(uid: firebaseUser.uid)
    }

    // uid の人をFirestoreで探して、見つかったかどうかで state を変える
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
            // 失敗したら、errorMessage にメッセージを入れて、 signedOut にする
            errorMessage = "ユーザー情報を読み込めませんでした。通信状態を確かめて、もう一度試してください。"
            state = .signedOut
        }
    }

    // Google でログイン → そのまま Firebase にもログイン
    func signIn() async {

        errorMessage = nil
        // GoogleService-Info.plist の CLIENT_ID を使う（固定文）
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage =
                "CLIENT_ID が見つかりません。GoogleService-Info.plist を確かめてください"
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID
        )

        // Google のログイン画面を重ねて表示するための、土台の画面（固定文）
        guard
            let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.keyWindow?.rootViewController
        else {
            errorMessage = "画面が見つかりません"
            return
        }

        do {
            // --- ここから ---
            // これらは、Google ログインと Firebase を組み合わせるときは、どのアプリでもこの形になる

            // Google のログイン画面を表示して、ログインさせる
            // result：Google のログイン結果（ユーザー情報）
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )

            // ログイン結果から ID トークンを取り出す
            // idToken：ID トークン（文字列）
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Googleでのログインがうまくいきませんでした。もう一度試してください。"
                return
            }

            // トークンから、Firebase 用の認証情報を作る（通信なし）
            // credential：認証情報
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            // 認証情報を使って Firebase にログインする
            // authResult:Firebase のログイン結果（uid を含むユーザー情報）
            let authResult = try await Auth.auth().signIn(with: credential)

            // --- ここまで ---

            // もらった uid を loadUser に渡して、state を変える
            await loadUser(uid: authResult.user.uid)

        } catch let error as GIDSignInError where error.code == .canceled {
            // キャンセルは失敗ではないので、何もしない
        } catch {
            errorMessage = "ログインできませんでした。もう一度試してください。"
        }
    }

    // 初回設定の完了：入力された内容で User を作って保存し、ホームへ進む
    func completeOnboarding(name: String, device: Device, bio: String?) async {

        isSaving = true  // 保存を始めた
        defer { isSaving = false }  // この関数を抜けるときに、必ず false に戻す

        errorMessage = nil
        // ログイン中の人の uid を取り出す。いなければ state を signedOut にして終わり
        guard let firebaseUser = Auth.auth().currentUser else {
            state = .signedOut
            return
        }
        // 受け取った device・name・bio と uid で User を作る
        let user = User(
            id: firebaseUser.uid,
            name: name,
            iconURL: nil,
            device: device,
            bio: bio
        )
        do {
            // repository の saveUser で保存する
            try await repository.saveUser(user)
            // 成功したら、state を signedIn にする
            state = .signedIn(user)
        } catch {
            // 失敗したら、errorMessage にメッセージを入れる（state は needsOnboarding のまま）
            errorMessage = "保存できませんでした。通信状態を確かめて、もう一度試してください。"
        }
    }

    // ログアウト：Firebase と Google の両方からログアウトして、ログイン画面に戻る
    func signOut() {
        do {
            // Firebase からログアウトする
            try Auth.auth().signOut()
            // Google からもログアウトする
            GIDSignIn.sharedInstance.signOut()
            // state を signedOut にする
            state = .signedOut

        } catch {
            errorMessage = "ログアウトに失敗しました。もう一度試してください。"
        }
    }

}
