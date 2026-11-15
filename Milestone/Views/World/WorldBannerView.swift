import SwiftUI

// 大看板：アイコン・ワールド名・星（お気に入り）・バージョン
// 星とバージョンは overlay で上に重ねる（場所を取らないので、ワールド名の幅を削らない）
struct WorldBannerView: View {
    let world: World
    let isFavorite: Bool  // お気に入りか
    let onToggleFavorite: () -> Void  // 星を押したときにすること
    var showsFavorite: Bool = true  // 星を出すか（登録の画面では出さない）

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
            Text(world.name)
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
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(
                            isFavorite
                                ? Color(red: 0.5, green: 0.88, blue: 0.74)
                                : .white.opacity(0.7)
                        )
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isFavorite ? "お気に入りから外す" : "お気に入りにする"
                )
                .padding(.top, 6)
                .padding(.trailing, 6)
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
        .background(world.gameMode.bannerColor)
    }
}
