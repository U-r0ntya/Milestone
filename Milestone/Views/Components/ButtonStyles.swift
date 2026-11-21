import SwiftUI

// メインのボタン：エメラルドのカプセルに白い文字（次へ・決定など）
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled   // 押せる状態かどうか

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .frame(minWidth: 120, minHeight: 48)
            .padding(.horizontal, 24)
            .background(isEnabled ? Color.accentColor : Color.gray.opacity(0.3))   // 押せないときは灰色
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)   // 押している間は少し薄く
    }
}

// .buttonStyle(.primary) と短く書けるようにする
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
