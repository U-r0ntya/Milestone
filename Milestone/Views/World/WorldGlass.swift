import SwiftUI

// ワールドの情報で使う、すりガラスの部品（背景の絵が少し透けて見える）

// すりガラスのカード：.worldGlass() と書くと付く
struct WorldGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)  // 昼でも暗いガラスにする
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(hex: 0x14100C, opacity: 0.34))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
            }
    }
}

extension View {
    func worldGlass(cornerRadius: CGFloat = 20) -> some View {
        modifier(WorldGlassModifier(cornerRadius: cornerRadius))
    }
}

// カードの見出し（小さな文字。アイコンも付けられる）
struct WorldCaption: View {
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.4)
        }
        .foregroundStyle(.white.opacity(0.72))
        .accessibilityAddTraits(.isHeader)
    }
}

// すりガラスの横長ボタン（名前を変える・更新する・削除する）
struct WorldGlassButtonStyle: ButtonStyle {
    var isDestructive = false  // 削除のボタンか（赤くする）
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: isDestructive ? .bold : .medium))
            .foregroundStyle(isDestructive ? Color(hex: 0xFFD9D5) : .white)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background {
                if isDestructive {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: 0xB3261E, opacity: 0.35))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color(hex: 0xFF786E, opacity: 0.55), lineWidth: 1)
                        }
                }
            }
            .modifier(OptionalGlass(isOn: !isDestructive))
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.7 : (isEnabled ? 1 : 0.5))  // 押している間・押せないときは薄く
    }

    // 削除のボタン以外に、すりガラスを付ける
    private struct OptionalGlass: ViewModifier {
        let isOn: Bool

        @ViewBuilder
        func body(content: Content) -> some View {
            if isOn {
                content.worldGlass(cornerRadius: 16)
            } else {
                content
            }
        }
    }
}

extension ButtonStyle where Self == WorldGlassButtonStyle {
    // .buttonStyle(.worldGlass) / .buttonStyle(.worldGlassDestructive) と短く書けるようにする
    static var worldGlass: WorldGlassButtonStyle { WorldGlassButtonStyle() }
    static var worldGlassDestructive: WorldGlassButtonStyle { WorldGlassButtonStyle(isDestructive: true) }
}
