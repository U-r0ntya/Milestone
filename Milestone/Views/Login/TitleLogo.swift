import SwiftUI

struct TitleLogo: View {
    var size: CGFloat = 36   // 文字の大きさ（指定しなければ 36）

    var body: some View {
        // 宝石 ＋「Mile（紫）stone（エメラルド）」
        HStack(spacing: size * 0.36) {            // 宝石と文字の間も、大きさに合わせる
            Image("LogoGem")
                .resizable()
                .scaledToFit()
                .frame(height: size * 1.45)       // 宝石の高さも、大きさに合わせる
            HStack(spacing: 0) {
                Text("Mile").foregroundStyle(.appTextPrimary)
                Text("stone").foregroundStyle(Color.accentColor)
            }
            .font(.system(size: size, weight: .semibold, design: .rounded))
        }
    }
}
