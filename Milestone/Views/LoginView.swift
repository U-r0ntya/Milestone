import SwiftUI

struct LoginView: View {
    let authViewModel: AuthViewModel
    @State private var showSheet = false
    var body: some View {
        VStack(spacing: 0) {
            // アプリ名（仮フォント及びタイトルロゴ）
            Text("Milestone").font(.system(size: 50)).bold()
            // サブタイトル（仮テキスト）
            Text("統合版プレイヤーのためのSNS").font(.system(size: 20)).padding(.bottom, 30)
            // ロゴ（仮アイコン）
            Image(systemName: "cube.fill").font(.system(size: 80)).padding(
                .bottom,
                30
            )

            // Google のログインボタン
            Button {
                Task { await authViewModel.signIn() }
            } label: {
                ZStack {
                    // 文字：ボタンのど真ん中
                    Text("Googleでログイン")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(
                            Color(
                                red: 31 / 255,
                                green: 31 / 255,
                                blue: 31 / 255
                            )
                        )
                    // Gアイコン：左端に寄せる
                    HStack {
                        Image("GoogleLogo")
                            .resizable()
                            .frame(width: 48, height: 48)
                        Spacer()
                    }
                    .padding(.leading, 10)
                }
                .frame(width: 300, height: 48)
                .background(
                    Color(red: 242 / 255, green: 242 / 255, blue: 242 / 255)
                )
                .clipShape(Capsule())
            }
            .padding(.bottom, 10)

            // 利用規約ボタン
            Button {
                showSheet = true
            } label: {
                Text("利用規約")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        Color(red: 31 / 255, green: 31 / 255, blue: 31 / 255)
                    )
                    .frame(width: 300, height: 48)
                    .background(.tint)
                    .clipShape(Capsule())
            }
            .sheet(isPresented: $showSheet) {
                Text("ここがシートの中身")  // 今後実装予定
            }

            // Minecraft の利用ガイドラインで必要な注意書き
            Text("Minecraft 公式の製品ではありません。Mojang および Microsoft が承認・関与しているものではありません。")
            .font(.caption2)
            .foregroundStyle(.secondary)  // 灰色
            .multilineTextAlignment(.center)  // 折り返した行も中央ぞろえ
            .frame(maxWidth: 300)
            .padding(.top, 24)  // 利用規約ボタンとの間をあける

            // エラーがあれば赤字で表示
            Text(authViewModel.errorMessage ?? "")  // エラーが無いときは空の文字
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .top)  // 高さ 48 は常に確保する
        }

    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel(repository: PreviewUserRepository()))
}

// プレビュー用の偽物の名簿係（通信しない）
struct PreviewUserRepository: UserRepository {
    func fetchUser(uid: String) async throws -> User? { nil }
    func saveUser(_ user: User) async throws {}
}
