import SwiftUI

// ワールドの1枚のカード（16:9 の写真カード）
// 写真の上に、左上：ランク（ランクがないときはゲームモード）、右上：お気に入りの星、
// 左下：最後に遊んだ日時とワールド名、右下：ワールドの日数
// 枠はランクの素材の色の細い線（ダークは右下へ暗く、ライトは右下へ白くなるグラデーション）
struct WorldCardView: View {
    let world: World
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    // 文字やバッジの位置（カードの 16:9 に合わせて、横 20・縦 11.25）
    private let sidePadding: CGFloat = 20
    private let topBottomPadding: CGFloat = 11.25

    // 写真の端を暗くしたり、下を暗くしたりするときの色（青みのある黒）
    private let shadeColor = Color(red: 6 / 255, green: 8 / 255, blue: 18 / 255)

    var body: some View {
        let style = WorldCardStyle(world: world)

        photo
            // 写真の端を暗くする（縁の線とのつなぎ目をなじませる）
            .overlay {
                RoundedRectangle(cornerRadius: 27)
                    .stroke(shadeColor.opacity(0.7), lineWidth: 22)
                    .blur(radius: 12)
            }
            // 下を少し暗くぼかす（文字を読みやすくする）
            .overlay { bottomShade }
            .overlay(alignment: .bottom) { bottomText }
            .overlay(alignment: .topLeading) { badge(style) }
            .overlay(alignment: .topTrailing) { starButton(style) }
            .clipShape(RoundedRectangle(cornerRadius: 27))
            // 細い縁の線（1pt）：グラデーションの板の上に、1pt 内側へ写真を置く
            .padding(1)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(style.frameGradient(isDark: isDark))
            }
            // 縁の少し内側に、もう1本うすい線
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    .padding(2)
            }
            // 外側のほのかな光（ダークだけ）と影
            .shadow(color: style.glow(isDark: isDark), radius: 14)
            .shadow(
                color: isDark ? .black.opacity(0.6) : Color(red: 30 / 255, green: 40 / 255, blue: 70 / 255).opacity(0.18),
                radius: isDark ? 15 : 12,
                y: isDark ? 10 : 8
            )
            .accessibilityElement(children: .contain)
    }

    // 写真（なければ、ゲームモードのアイコンを置いた暗い板）
    private var photo: some View {
        Color.clear
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay {
                if let image = WorldPhotoStore.shared.image(for: world.id) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .accessibilityHidden(true)
                } else {
                    LinearGradient(
                        colors: [Color(hex: 0x2A3270), Color(hex: 0x14193A)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay {
                        Image(systemName: world.gameMode.iconName)
                            .font(.system(size: 64))
                            .foregroundStyle(.white.opacity(0.12))
                    }
                    .accessibilityHidden(true)
                }
            }
            .clipped()
    }

    // 下のほうだけ、ぼかして少し暗くする（上は写真のまま）
    private var bottomShade: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)  // ライトでも暗いぼかしにする
                .opacity(0.6)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.65),
                            .init(color: .black, location: 0.9),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.65),
                    .init(color: shadeColor.opacity(0.4), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
    }

    // 左下：最後に遊んだ日時とワールド名　右下：ワールドの日数
    private var bottomText: some View {
        HStack(alignment: .lastTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                if let lastPlayed = world.lastPlayed {
                    // 「3時間前」のような表示。日本語で出すために、ロケールを指定する
                    Text(
                        "\(lastPlayed.formatted(.relative(presentation: .numeric, unitsStyle: .wide).locale(Locale(identifier: "ja_JP"))))に遊んだ"
                    )
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.78))
                }
                Text(world.displayName)
                    .font(.system(size: 22, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
            if let time = world.time {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(time / 24000)")
                        .font(.system(size: 24, weight: .semibold).width(.condensed))
                    Text("日目")
                        .font(.system(size: 11, weight: .medium))
                }
                .accessibilityElement(children: .combine)
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.55), radius: 3, y: 1)
        .padding(.horizontal, sidePadding)
        .padding(.bottom, topBottomPadding)
    }

    // 左上：ランクのバッジ（ガラス。縁はカードの枠と同じ色）
    private func badge(_ style: WorldCardStyle) -> some View {
        Text(style.label)
            .font(.system(size: 10.5, weight: .semibold))
            .lineLimit(1)
            .foregroundStyle(Color(hex: 0xF4F4F8))
            .padding(.horizontal, 13)
            .frame(height: 26)
            .background(.ultraThinMaterial, in: Capsule())
            .environment(\.colorScheme, .dark)  // ライトでも暗いガラスにする
            .overlay {
                Capsule().strokeBorder(style.frameGradient(isDark: isDark), lineWidth: 1)
            }
            .overlay {
                Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 1).padding(1)
            }
            .padding(.leading, sidePadding)
            .padding(.top, topBottomPadding)
    }

    // 右上：お気に入りの星（ガラスの丸。お気に入りは白で塗る）
    private func starButton(_ style: WorldCardStyle) -> some View {
        Button(action: onToggleFavorite) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(isFavorite ? 1 : 0.85))
                .contentTransition(.symbolEffect(.replace))  // 星の形が、なめらかに入れかわる
                .symbolEffect(.bounce, value: isFavorite)  // 押したときに、ぴょんと弾む
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
                .environment(\.colorScheme, .dark)
                .overlay {
                    Circle().strokeBorder(style.frameGradient(isDark: isDark), lineWidth: 1)
                }
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1).padding(1)
                }
                .frame(width: 44, height: 44)  // 指で押せる広さは、丸より大きく取る
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "お気に入りから外す" : "お気に入りにする")
        // 丸の位置を、右から 20・上から 11.25 にそろえる（押せる広さのぶん、4 ずつ外へ出す）
        .padding(.trailing, sidePadding - 4)
        .padding(.top, topBottomPadding - 4)
    }
}
