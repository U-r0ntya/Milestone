import SwiftUI
import UIKit

// サブ看板の中身：最後に遊んだ日時、ゲームモード・難易度のラベル、ランク、
// 一覧では日数とシード値のコピーの1行、登録の画面では詳細の表
struct WorldSubBannerView: View {
    let world: World
    let ownerName: String  // 持ち主の名前（今は自分のワールドだけなので、ログイン中の人）
    var showsDetails: Bool = true  // 詳細の表を出すか（一覧では出さず、ランクのバーまでにする。登録の画面では出す）
    var isGlass: Bool = false  // 一覧のガラスの見た目にするか（白い文字、ラベルは背景なしの色文字）
    @Environment(\.colorScheme) private var colorScheme  // 夜（ダーク）なら、難易度の色を明るくする
    @State private var showsCopied = false  // コピーできたチェックを出しているか
    @State private var copyCount = 0  // コピーした回数（押すたびに、チェックを出しなおす合図）

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
                    .foregroundStyle(accentColor)
                }

                Spacer(minLength: 0)

                if isGlass {
                    // ガラスの上では、背景を付けず、文字の色だけで見分ける
                    HStack(spacing: 10) {
                        Text(world.gameMode.displayName)
                            .foregroundStyle(world.gameMode.listLabelColor)
                        if world.gameMode.showsDifficulty, let difficulty = world.difficulty {
                            Text(difficulty.displayName)
                                .foregroundStyle(difficulty.listLabelColor(isNight: colorScheme == .dark))
                        }
                    }
                    .font(.caption.bold())
                } else {
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
            }

            // ランク（サバイバルで、日数（time）があるときだけ）
            if world.gameMode == .survival, world.time != nil {
                WorldRankView(rank: WorldRank(world: world), isGlass: isGlass)
            }

            // 詳細の表（2列）は、登録の画面だけ。一覧では、日数とシード値のコピーの1行だけにする
            if showsDetails {
                detailGrid
            } else if world.time != nil || world.seed != nil {
                summaryRow
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // 一覧の1行：左にワールドの日数、右にシード値（押すとコピーする。何回でも押せる）
    private var summaryRow: some View {
        HStack(spacing: 8) {
            if let time = world.time {
                Label("\(time / 24000)日目", systemImage: "calendar")
                    .foregroundStyle(primaryColor)
            }
            Spacer(minLength: 0)
            if let seed = world.seed {
                Button {
                    UIPasteboard.general.string = "\(seed)"  // シード値をコピーする
                    copyCount += 1
                    showsCopied = true
                } label: {
                    HStack(spacing: 4) {
                        // コピーできたら、左にチェックを出す（少しすると消える）
                        if showsCopied {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(accentColor)
                                .symbolEffect(.bounce, value: copyCount)  // 押すたびに弾む
                                .transition(.scale.combined(with: .opacity))
                        }
                        Text("シード値")
                            .font(isGlass ? Font.caption.weight(.medium) : nil)
                            .foregroundStyle(secondaryColor)
                        Text("\(seed)")
                            .font(isGlass ? Font.caption2 : nil)
                            .foregroundStyle(primaryColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)  // 長いシード値は、少し小さくして1行に収める
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(accentColor)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())  // 文字のすきまも押せるようにする
                }
                .buttonStyle(.plain)  // カードを押して情報の画面に進むのと、分ける
                .accessibilityLabel("シード値をコピー")
            }
        }
        .font(.subheadline.weight(.medium))
        .animation(.snappy, value: showsCopied)
        // 押すたびに、1.5 秒たったらチェックを消す（続けて押すと、前の待ちは取り消されて、数えなおす）
        .task(id: copyCount) {
            guard copyCount > 0 else { return }
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            showsCopied = false
        }
    }

    // ガラスのときと、ふつうのときの文字の色
    private var primaryColor: Color {
        isGlass ? .white : Color.appTextPrimary
    }

    private var secondaryColor: Color {
        isGlass ? .white.opacity(0.72) : Color.appTextSecondary
    }

    private var accentColor: Color {
        isGlass ? .worldListAccent : world.gameMode.accentColor
    }

    // 詳細の表（2列）
    private var detailGrid: some View {
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
                        .foregroundStyle(secondaryColor)
                    Text(item.value)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(primaryColor)
                        .lineLimit(1)
                }
            }
        }
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
