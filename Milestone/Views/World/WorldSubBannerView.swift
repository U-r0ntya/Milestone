import SwiftUI

// サブ看板の中身：最後に遊んだ日時、ゲームモード・難易度のラベル、詳細の表
struct WorldSubBannerView: View {
    let world: World
    let ownerName: String  // 持ち主の名前（今は自分のワールドだけなので、ログイン中の人）

    // 詳細の表の1項目
    private struct DetailItem: Identifiable {
        let label: String
        let value: String
        var id: String { label }
    }

    // 入っている項目だけを並べる（Optional の項目は、値がなければ出さない）
    private var details: [DetailItem] {
        var items: [DetailItem] = []
        if let time = world.time {
            items.append(DetailItem(label: "ワールドの日数", value: "\(time / 24000)日目"))
        }
        items.append(DetailItem(label: "持ち主", value: ownerName))
        items.append(DetailItem(label: "チート", value: world.commandsEnabled ? "ON" : "OFF"))
        items.append(DetailItem(label: "マルチプレイ", value: world.isMultiplayer ? "ON" : "OFF"))
        if let permission = world.playerPermission {
            items.append(DetailItem(label: "自分の権限", value: permission.displayName))
        }
        if let used = world.hasUsedCheats {
            items.append(
                DetailItem(label: "クリエイティブ・チートの使用", value: used ? "使った" : "使っていない")
            )
        }
        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 上の段：最後に遊んだ日時と、ラベル
            HStack(spacing: 6) {
                if let lastPlayed = world.lastPlayed {
                    Label {
                        Text(
                            // 「3時間前」のような表示。日本語で出すために、ロケールを指定する
                            "\(lastPlayed.formatted(.relative(presentation: .numeric, unitsStyle: .wide).locale(Locale(identifier: "ja_JP"))))に遊んだ"
                        )
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(world.gameMode.accentColor)
                }

                Spacer(minLength: 0)

                label(
                    world.gameMode.displayName,
                    background: world.gameMode.bannerColor,
                    text: .white
                )
                if world.gameMode.showsDifficulty, let difficulty = world.difficulty {
                    label(
                        difficulty.displayName,
                        background: difficulty.labelBackgroundColor,
                        text: difficulty.labelTextColor
                    )
                }
            }

            // ランク（サバイバルで、日数（time）があるときだけ。手で入力したワールドは出さない）
            if world.gameMode == .survival, world.time != nil {
                WorldRankView(rank: WorldRank(world: world))
            }

            // 詳細の表（2列）
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), alignment: .leading),
                    GridItem(.flexible(), alignment: .leading),
                ],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(details) { item in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.label)
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                        Text(item.value)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // ゲームモード・難易度の丸いラベル
    private func label(_ text: String, background: Color, text textColor: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(background, in: Capsule())
    }
}
