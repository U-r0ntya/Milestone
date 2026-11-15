import SwiftUI

// ワールドの1枚のカード：大看板＋サブ看板（開閉できる）
// サブ看板は、全部出すか全部隠すかの2通り。とじているときは矢印のボタンだけが残る
struct WorldCardView: View {
    let world: World
    let ownerName: String
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    @State private var isOpen: Bool  // サブ看板を開いているか

    // startsOpen：初めに開いておくか（お気に入りと最近は true、残りは false）
    init(
        world: World,
        ownerName: String,
        isFavorite: Bool,
        startsOpen: Bool,
        onToggleFavorite: @escaping () -> Void
    ) {
        self.world = world
        self.ownerName = ownerName
        self.isFavorite = isFavorite
        self.onToggleFavorite = onToggleFavorite
        _isOpen = State(initialValue: startsOpen)
    }

    var body: some View {
        VStack(spacing: 0) {
            WorldBannerView(
                world: world,
                isFavorite: isFavorite,
                onToggleFavorite: onToggleFavorite
            )

            if isOpen {
                WorldSubBannerView(world: world, ownerName: ownerName)
                Divider().padding(.horizontal, 14)
            }

            // 開閉ボタン（矢印だけ）
            Button {
                withAnimation { isOpen.toggle() }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.footnote.bold())
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)  // 押しやすいように高くする（指で押せる大きさは 44pt くらいが目安）
                    .contentShape(Rectangle())  // 透明なところも、押せる範囲に入れる
            }
            .buttonStyle(.plain)
            .foregroundStyle(world.gameMode.accentColor)
            .accessibilityLabel(isOpen ? "とじる" : "くわしく見る")
        }
        .background(world.gameMode.tintColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
