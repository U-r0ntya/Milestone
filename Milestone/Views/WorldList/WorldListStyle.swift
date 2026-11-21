import SwiftUI

// ワールドの一覧（空の背景）で使う、ガラスの部品と色

// 一覧のガラスのカード：.worldListGlass() と書くと付く
// 後ろの空が透けて見えるように、色はほとんど重ねず、ぼかしと白いふちだけにする
struct WorldListGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(0.35)  // ぼかしを弱くして、空の色を残す
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
            }
    }
}

// ガラスの丸（星のボタン・「ワールドを登録」の＋）
struct WorldListGlassCircleModifier: ViewModifier {
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(.white.opacity(0.16), in: Circle())
            .overlay {
                Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1)
            }
            // 上のふちに、内側から細い光を入れる
            .overlay(alignment: .top) {
                Circle()
                    .trim(from: 0.6, to: 0.9)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
                    .padding(1.5)
            }
    }
}

extension View {
    func worldListGlass(cornerRadius: CGFloat = 20) -> some View {
        modifier(WorldListGlassModifier(cornerRadius: cornerRadius))
    }

    func worldListGlassCircle(size: CGFloat) -> some View {
        modifier(WorldListGlassCircleModifier(size: size))
    }
}

// 一覧のガラスで使う決まった色
extension Color {
    static let worldListAccent = Color(hex: 0x7FE0BD)  // 「遊んだ」・＋・コピー・開閉の矢印
}

// 左上が暗く、右下に向かって明るくなる斜めのグラデーション
// colors は「左上（暗い）→ まん中 → 右下（明るい）」の順
func makeWorldListGradient(_ colors: [Color]) -> LinearGradient {
    LinearGradient(
        stops: [
            .init(color: colors[0], location: 0),
            .init(color: colors[1], location: 0.45),
            .init(color: colors[2], location: 1),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// 緑のグラデーションのガラスのボタン（大看板のサバイバルより濃い緑。白い文字がはっきり読めるように）
struct WorldListGradientButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                makeWorldListGradient([
                    Color(hex: 0x0B5640, opacity: 0.9),
                    Color(hex: 0x1C8A5E, opacity: 0.85),
                    Color(hex: 0x3FBF85, opacity: 0.85),
                ]),
                in: Capsule()
            )
            .background(.ultraThinMaterial.opacity(0.35), in: Capsule())  // 後ろを少しぼかす
            .overlay {
                Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 1)
            }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : (isEnabled ? 1 : 0.5))  // 押している間・押せないときは薄く
    }
}

extension ButtonStyle where Self == WorldListGradientButtonStyle {
    // .buttonStyle(.worldListGradient) と短く書けるようにする
    static var worldListGradient: WorldListGradientButtonStyle { WorldListGradientButtonStyle() }
}
