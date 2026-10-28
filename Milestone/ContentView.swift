import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

// 技術検証用：Google でログインして、Firebase の uid が取れるか確かめる
struct ContentView: View {
    @State private var uid: String?
    @State private var userName: String?
    @State private var errorMessage: String?
    @State private var showFirestoreCheck = false
    @State private var showStorageCheck = false
    @State private var showLevelDatCheck = false

    var body: some View {
        VStack(spacing: 20) {
            if let uid {
                Text("ログイン中：\(userName ?? "名前なし")")
                Text("uid：\(uid)")
                    .font(.caption)
                Button("ログアウト") {
                    signOut()
                }
                Button("Firestore の検証を開く") {
                    showFirestoreCheck = true
                }
                Button("Storage の検証を開く") {
                    showStorageCheck = true
                }
                Button("level.dat の検証を開く") {
                    showLevelDatCheck = true
                }
            } else {
                GoogleSignInButton {
                    Task {
                        await signIn()
                    }
                }
                .frame(width: 240, height: 50)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .sheet(isPresented: $showFirestoreCheck) {
            FirestoreCheckView()
        }
        .sheet(isPresented: $showStorageCheck) {
            StorageCheckView()
        }
        .sheet(isPresented: $showLevelDatCheck) {
            LevelDatCheckView()
        }
        .onAppear {
            // すでにログインしていれば、その人を表示する
            if let user = Auth.auth().currentUser {
                uid = user.uid
                userName = user.displayName
            }
        }
    }

    // Google でログイン → そのまま Firebase にもログイン
    func signIn() async {
        // GoogleService-Info.plist の CLIENT_ID を使う
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage =
                "CLIENT_ID が見つかりません。GoogleService-Info.plist を確かめてください"
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID
        )

        // Google のログイン画面を出すための、今の画面
        guard
            let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.keyWindow?.rootViewController
        else {
            errorMessage = "画面が見つかりません"
            return
        }

        do {
            // 1. Google にログインする
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google の ID トークンが取れませんでした"
                return
            }

            // 2. Google のログイン情報で、Firebase にログインする
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)

            // 3. Firebase が作った uid を表示する
            uid = authResult.user.uid
            userName = authResult.user.displayName
            errorMessage = nil
        } catch {
            errorMessage = "ログインに失敗しました：\(error.localizedDescription)"
        }
    }

    // Firebase と Google の両方からログアウトする
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            uid = nil
            userName = nil
        } catch {
            errorMessage = "ログアウトに失敗しました"
        }
    }
}

#Preview {
    ContentView()
}
