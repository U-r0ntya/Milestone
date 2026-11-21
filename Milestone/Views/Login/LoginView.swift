import SwiftUI

struct LoginView: View {
    let authViewModel: AuthViewModel
    // true にすると、ロゴだけを見せる（ロード画面に使う。ロゴの位置がログイン画面とぴったり同じになる）
    var showsOnlyLogo = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            // アプリ名のロゴ（宝石＋Milestone）
            TitleLogo(size: 48)
            Group {
                Text("Minecraftのワールドを管理するアプリ")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.appTextSecondary)
                    .padding(.top, 10)
                Text("iPhone、iPad専用")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.appTextSecondary)
            }
            .opacity(showsOnlyLogo ? 0 : 1)  // ロード画面のときは、ロゴのほかは見えなくする（場所だけ取る）
            .allowsHitTesting(!showsOnlyLogo)
            .accessibilityHidden(showsOnlyLogo)
            Spacer()
            Group {
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
                .disabled(authViewModel.isSigningIn)
                .opacity(authViewModel.isSigningIn ? 0.5 : 1)

                // Minecraft の利用ガイドラインで必要な注意書き
                Text(
                    "Minecraft 公式の製品ではありません。Mojang および Microsoft が承認・関与しているものではありません。"
                )
                .font(.caption2)
                .foregroundStyle(.appTextSecondary)  // 控えめな文字色（ダークではうすい紫）
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
            .opacity(showsOnlyLogo ? 0 : 1)  // ロード画面のときは、ロゴのほかは見えなくする（場所だけ取る）
            .allowsHitTesting(!showsOnlyLogo)
            .accessibilityHidden(showsOnlyLogo)
        }

    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel(repository: MockUserRepository()))
}

