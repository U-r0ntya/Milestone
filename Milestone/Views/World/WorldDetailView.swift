import SwiftUI
import UIKit

// ワールドの情報の画面：大看板・名前を変える・ランク・全部の情報・下のボタン
// 一覧のカードを押すと、ここに進む。レイアウトを見るための土台（ボタンはまだ動かない。シード値のコピーだけ動く）
struct WorldDetailView: View {
    let user: User  // ログイン中の人
    let world: World
    let viewModel: WorldListViewModel  // お気に入りの切りかえに使う（一覧と同じものを受け取る）
    @State private var didCopySeed = false  // シード値をコピーしたか（アイコンを切りかえる）

    // 表の1行
    private struct Row: Identifiable {
        let label: String
        let value: String
        var copyText: String? = nil  // 入っていれば、右にコピーのボタンを出す
        var id: String { label }
    }

    // 表の1つのまとまり（SwiftUI の Section と名前が重ならないように InfoGroup）
    private struct InfoGroup: Identifiable {
        let title: String
        let rows: [Row]
        var id: String { title }
    }

    // 入っているデータは、全部出す（Optional の項目は、値がなければ行を出さない）
    private var sections: [InfoGroup] {
        // ワールド
        var worldRows: [Row] = [
            Row(label: "ゲームモード", value: world.gameMode.displayName)
        ]
        if let difficulty = world.difficulty {
            worldRows.append(Row(label: "難易度", value: difficulty.displayName))
        }
        if let time = world.time {
            worldRows.append(Row(label: "ワールドの日数", value: "\(time / 24000)日目"))
        }
        if let worldType = world.worldType {
            worldRows.append(Row(label: "ワールドの種類", value: worldType.displayName))
        }
        if let seed = world.seed {
            worldRows.append(Row(label: "シード値", value: "\(seed)", copyText: "\(seed)"))
        }
        if let spawn = world.spawnPoint {
            worldRows.append(
                Row(label: "スポーン地点", value: "\(spawn.x) / \(spawn.y) / \(spawn.z)")
            )
        }

        // 設定
        var settingRows: [Row] = [
            Row(label: "チート", value: world.commandsEnabled ? "ON" : "OFF"),
            Row(label: "マルチプレイ", value: world.isMultiplayer ? "ON" : "OFF"),
        ]
        if let used = world.hasUsedCheats {
            settingRows.append(
                Row(label: "クリエイティブ・チートの使用", value: used ? "使った" : "使っていない")
            )
        }
        if let required = world.texturePacksRequired {
            settingRows.append(
                Row(label: "リソースパックが必須か", value: required ? "必須" : "必須ではない")
            )
        }
        if let permission = world.playerPermission {
            settingRows.append(Row(label: "自分の権限", value: permission.displayName))
        }

        // 記録
        var recordRows: [Row] = []
        if let version = world.lastOpenedVersion {
            recordRows.append(Row(label: "最後に開いたバージョン", value: version))
        }
        if let lastPlayed = world.lastPlayed {
            recordRows.append(Row(label: "最後に遊んだ日時", value: dateText(lastPlayed)))
        }
        recordRows.append(Row(label: "登録した日時", value: dateText(world.createdAt)))
        recordRows.append(Row(label: "機種", value: world.device.displayName))
        recordRows.append(Row(label: "持ち主", value: user.name))
        if let folderName = world.folderName {
            recordRows.append(Row(label: "フォルダ名", value: folderName))
        }

        return [
            InfoGroup(title: "ワールド", rows: worldRows),
            InfoGroup(title: "設定", rows: settingRows),
            InfoGroup(title: "記録", rows: recordRows),
        ]
    }

    // 日時を「2026年11月15日 17:40」の形にする（日本語で出すために、ロケールを指定する）
    private func dateText(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(date: .long, time: .shortened)
                .locale(Locale(identifier: "ja_JP"))
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 大看板（星でお気に入りを切りかえる）
                WorldBannerView(
                    world: world,
                    isFavorite: viewModel.favoriteWorldId == world.id,
                    onToggleFavorite: {
                        Task {
                            await viewModel.toggleFavorite(
                                userId: user.id,
                                worldId: world.id
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

                renameRow

                // ランク（サバイバルで、日数（time）があるときだけ）
                if world.gameMode == .survival, world.time != nil {
                    card {
                        WorldRankView(rank: WorldRank(world: world))
                    }
                }

                ForEach(sections) { section in
                    sectionCard(section)
                }

                bottomButtons
            }
            .padding(16)
        }
        .appHeader("ワールドの情報")
    }

    // 「名前を変える」の行（押すと、入力の小さな画面を出す。まだ動かない）
    private var renameRow: some View {
        Button {
            // TODO: 名前を変える画面（シート）を出す
        } label: {
            HStack {
                Label("ワールド名を変える", systemImage: "pencil")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // 表の1つのまとまり（見出し＋行）
    private func sectionCard(_ section: InfoGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(.subheadline.bold())
                .foregroundStyle(Color.appTextSecondary)
                .padding(.leading, 4)

            card {
                VStack(spacing: 0) {
                    ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                        if index > 0 { Divider() }
                        rowView(row)
                    }
                }
            }
        }
    }

    // 1行：左に項目名、右に値（コピーできる項目は、いちばん右にアイコン）
    private func rowView(_ row: Row) -> some View {
        HStack(spacing: 8) {
            Text(row.label)
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
            Spacer(minLength: 8)
            Text(row.value)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.trailing)
            if let copyText = row.copyText {
                Button {
                    UIPasteboard.general.string = copyText
                    didCopySeed = true
                } label: {
                    Image(systemName: didCopySeed ? "checkmark" : "doc.on.doc")
                        .font(.footnote)
                        .foregroundStyle(Color.appTagText)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("シード値をコピー")
            }
        }
        .padding(.vertical, 10)
    }

    // 下のボタン（6-7 で動かす。いまはレイアウトを見るために置いてある）
    private var bottomButtons: some View {
        VStack(spacing: 10) {
            Button {
                // TODO(6-7): level.dat を選びなおして更新する
            } label: {
                Text("level.dat を選びなおして更新")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary)

            Button(role: .destructive) {
                // TODO(6-7): このワールドを削除する
            } label: {
                Text("このワールドを削除")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .padding(.top, 8)
    }

    // 白いカードの枠
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appCardBorder, lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        WorldDetailView(
            user: User(
                id: "preview",
                name: "たいき",
                iconURL: nil,
                device: .iPhone,
                bio: nil
            ),
            world: World(
                id: "preview-world-1",
                ownerId: "preview",
                device: .iPhone,
                createdAt: Date().addingTimeInterval(-24 * 60 * 60),
                name: "サバイバル1",
                seed: -1_234_567_890_123,
                gameMode: .survival,
                difficulty: .normal,
                spawnPoint: BlockPosition(x: 0, y: 64, z: 0),
                lastOpenedVersion: "1.21.40",
                lastPlayed: Date().addingTimeInterval(-3 * 60 * 60),
                time: 240_000_000,
                worldType: .infinite,
                commandsEnabled: false,
                hasUsedCheats: false,
                isMultiplayer: true,
                texturePacksRequired: false,
                playerPermission: .member,
                folderName: "preview-folder-1"
            ),
            viewModel: WorldListViewModel(
                repository: MockWorldRepository(),
                userRepository: MockUserRepository(),
                favoriteWorldId: nil
            )
        )
    }
}
