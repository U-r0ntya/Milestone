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
