import SwiftUI
import UniformTypeIdentifiers

// 技術検証用：level.dat を選んで、中の値を表示する（確かめたら消す）
struct LevelDatCheckView: View {
    @State private var showImporter = false
    @State private var rows: [(String, String)] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("level.dat を選ぶ") {
                        showImporter = true
                    }
                }
                if let errorMessage {
                    Section("エラー") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
                Section("読み込んだ値") {
                    ForEach(rows, id: \.0) { row in
                        HStack {
                            Text(row.0)
                            Spacer()
                            Text(row.1)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("level.dat（検証）")
            // 「ファイル」アプリの画面を出す。level.dat は決まった種類がないので、何でも選べる .data にする
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data]) { result in
                switch result {
                case .success(let url):
                    read(url)
                case .failure(let error):
                    errorMessage = "ファイルを選べませんでした：\(error.localizedDescription)"
                }
            }
        }
    }

    private func read(_ url: URL) {
        errorMessage = nil
        rows = []

        // ほかのアプリの場所にあるファイルを読むときは、読む間だけ許可をもらう
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let root = try NBTReader.readLevelDat(data)

            // バージョンは [1, 26, 52, 3, 0] のような並びなので、最初の3つを「.」でつなぐ
            let version = root["lastOpenedWithVersion"]?.listValue?
                .compactMap { $0.intValue }
                .prefix(3)
                .map { String($0) }
                .joined(separator: ".") ?? "なし"

            // SpawnY の 32767 は「高さがまだ決まっていない」という意味
            let spawnY: String
            if let y = root["SpawnY"]?.intValue, y != 32767 {
                spawnY = String(y)
            } else {
                spawnY = "未決定"
            }

            let time = root["Time"]?.intValue ?? 0

            rows = [
                ("ワールドの名前", root["LevelName"]?.stringValue ?? "なし"),
                ("シード値", root["RandomSeed"]?.intValue.map { String($0) } ?? "なし"),
                ("ゲームモード", root["GameType"]?.intValue.map { String($0) } ?? "なし"),
                ("難易度", root["Difficulty"]?.intValue.map { String($0) } ?? "なし"),
                ("ワールドの種類", root["Generator"]?.intValue.map { String($0) } ?? "なし"),
                ("スポーン地点", "X: \(root["SpawnX"]?.intValue ?? 0)  Y: \(spawnY)  Z: \(root["SpawnZ"]?.intValue ?? 0)"),
                ("最後に開いたバージョン", version),
                ("チートが有効か", root["commandsEnabled"]?.intValue == 1 ? "オン" : "オフ"),
                ("マルチプレイ", root["MultiplayerGame"]?.intValue == 1 ? "できる" : "できない"),
                ("クリエイティブ・チートを使ったか", root["hasBeenLoadedInCreative"]?.intValue == 1 ? "使った" : "使っていない"),
                ("始まってからの日数", "\(time / 24000) 日目"),
                ("読めた項目の数", "\(root.count) 個")
            ]
        } catch {
            errorMessage = "読み込めませんでした：\(error)"
        }
    }
}
