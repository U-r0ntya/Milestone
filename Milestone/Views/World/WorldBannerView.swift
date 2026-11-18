import SwiftUI

// 大看板：アイコン・ワールド名・星（お気に入り）・バージョン
// 星とバージョンは overlay で上に重ねる（場所を取らないので、ワールド名の幅を削らない）
// isGlass：一覧（空の背景）のときは、グラデーションの半透明の帯と、ガラスの丸の星にする
struct WorldBannerView: View {
    let world: World
    let isFavorite: Bool  // お気に入りか
    let onToggleFavorite: () -> Void  // 星を押したときにすること
    var showsFavorite: Bool = true  // 星を出すか（登録の画面では出さない）
    var isGlass: Bool = false  // 一覧のガラスの見た目にするか

    var body: some View {
        HStack(spacing: 12) {
            // ゲームモードのアイコン
            Image(systemName: world.gameMode.iconName)
                .font(.system(size: 26))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    .white.opacity(0.18),
                    in: RoundedRectangle(cornerRadius: 12)
                )

            // ワールド名（右に星のぶんの余白を空けて、星と重ならないようにする）
            Text(world.displayName)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 36)
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 12)
        // 右上：星（お気に入りの切りかえ）
        .overlay(alignment: .topTrailing) {
            if showsFavorite {
                Button(action: onToggleFavorite) {
                    if isGlass {
                        // ガラスの丸の中に、小さめの星（お気に入りは白で塗る）
                        star
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isFavorite ? .white : .white.opacity(0.7))
                            .worldListGlassCircle(size: 30)
                            .frame(width: 44, height: 44)  // 指で押せる広さは、丸より大きく取る
                            .contentShape(Rectangle())
                    } else {
                        star
                            .font(.title3)
                            .foregroundStyle(
                                isFavorite
                                    ? Color(red: 0.5, green: 0.88, blue: 0.74)
                                    : .white.opacity(0.7)
                            )
                            .frame(width: 36, height: 36)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isFavorite ? "お気に入りから外す" : "お気に入りにする"
                )
                .padding(.top, isGlass ? 0 : 6)
                .padding(.trailing, isGlass ? 0 : 6)
            }
        }
        // 右下：バージョン（level.dat に入っていたときだけ出す）
        .overlay(alignment: .bottomTrailing) {
            if let version = world.lastOpenedVersion {
                Text(version)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.trailing, 14)
                    .padding(.bottom, 10)
            }
        }
        .background {
            if isGlass {
                // 半透明のグラデーション（後ろの空が透ける）と、下のふちの細い線
                Rectangle()
                    .fill(world.gameMode.listBannerGradient)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(.white.opacity(0.14))
                            .frame(height: 1)
                    }
            } else {
                world.gameMode.bannerColor
            }
        }
    }

    // 星のアイコン（形の入れかわりと、押したときの弾む動き）
    private var star: some View {
        Image(systemName: isFavorite ? "star.fill" : "star")
            .contentTransition(.symbolEffect(.replace))  // 星の形が、なめらかに入れかわる
            .symbolEffect(.bounce, value: isFavorite)  // 押したときに、ぴょんと弾む
    }
}
