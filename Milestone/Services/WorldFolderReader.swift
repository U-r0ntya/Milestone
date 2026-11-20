import Foundation

// 「ファイル」アプリで選んだものから、ワールドの level.dat と写真を読み出す
// 選べるもの：
// - Minecraft フォルダ（この iPhone 内 → Minecraft）：中の minecraftWorlds から、全部のワールドを読む
// - ワールドのフォルダ：そのワールドだけを読む
// - level.dat：そのワールドだけを読む（同じフォルダのほかのファイルを読む許可がないので、写真はなし）
// 写真は、screenshot_icon_数字 の中で数字がいちばん大きいもの → なければ world_icon
enum WorldFolderReader {
    // 1つのワールドを読み出した結果
    struct Result {
        let levelDat: Data  // level.dat の中身
        let folderName: String  // ワールドのフォルダ名（同じワールドを2回登録しないための目印）
        let photo: Data?  // ワールドの写真（見つからなければ nil）
        var fromMinecraftFolder = false  // Minecraft フォルダの中から探して読んだか
    }

    // 読めなかったとき
    enum ReadError: Error {
        case cannotRead  // 読む許可がない・ファイルが壊れている
        case notFound  // ワールドが見つからない
    }

    // 写真が大きすぎるときは読まない（ふつうは 200KB くらい）
    private static let maxPhotoBytes = 10 * 1024 * 1024

    // MARK: - 全部のワールド

    // Minecraft フォルダ（または games・com.mojang・minecraftWorlds のどれか）から、全部のワールドを読む
    // 読めなかったワールドは飛ばす
    static func readAll(from url: URL) throws -> [Result] {
        // 選んだフォルダを読む許可を取る（中のフォルダとファイルも読める）
        guard url.startAccessingSecurityScopedResource() else {
            throw ReadError.cannotRead
        }
        defer { url.stopAccessingSecurityScopedResource() }  // 抜けるときに、必ず読み終わりを伝える

        guard let worldsFolder = worldsFolder(in: url) else {
            throw ReadError.notFound
        }
        let folders =
            (try? FileManager.default.contentsOfDirectory(
                at: worldsFolder,
                includingPropertiesForKeys: [.isDirectoryKey]
            )) ?? []

        return folders
            .filter { isDirectory($0) }
            .compactMap { folder in
                guard var result = try? readWorldFolder(folder) else { return nil }
                result.fromMinecraftFolder = true
                return result
            }
    }

    // MARK: - 1つのワールド

    // 1つのワールドを読む
    // url が Minecraft フォルダのときは、worldFolderName のワールドを中から探す
    static func read(from url: URL, worldFolderName: String? = nil) throws -> Result {
        guard url.startAccessingSecurityScopedResource() else {
            throw ReadError.cannotRead
        }
        defer { url.stopAccessingSecurityScopedResource() }

        if isDirectory(url) {
            // ワールドのフォルダ（中に level.dat がある）
            if FileManager.default.fileExists(atPath: url.appendingPathComponent("level.dat").path) {
                return try readWorldFolder(url)
            }
            // Minecraft フォルダ：中から、同じフォルダ名のワールドを探す
            guard let worldFolderName, let worldsFolder = worldsFolder(in: url) else {
                throw ReadError.notFound
            }
            var result = try readWorldFolder(worldsFolder.appendingPathComponent(worldFolderName))
            result.fromMinecraftFolder = true
            return result
        }

        // level.dat だけ（level.dat_old などは断る）
        guard url.lastPathComponent == "level.dat" else {
            throw ReadError.cannotRead
        }
        return Result(
            levelDat: try Data(contentsOf: url),
            folderName: url.deletingLastPathComponent().lastPathComponent,
            photo: nil
        )
    }

    // MARK: - 中で使う部品（読む許可は、呼ぶ側で取ってある）

    // ワールドのフォルダから、level.dat と写真を読む
    private static func readWorldFolder(_ folder: URL) throws -> Result {
        guard let data = try? Data(contentsOf: folder.appendingPathComponent("level.dat")) else {
            throw ReadError.notFound
        }
        return Result(levelDat: data, folderName: folder.lastPathComponent, photo: readPhoto(in: folder))
    }

    // ワールドが並んでいるフォルダ（minecraftWorlds）を探す
    // 選んだのが Minecraft・games・com.mojang・minecraftWorlds のどれでも見つかるようにする
    private static func worldsFolder(in root: URL) -> URL? {
        if root.lastPathComponent == "minecraftWorlds" {
            return root
        }
        let candidates = [
            "games/com.mojang/minecraftWorlds",
            "com.mojang/minecraftWorlds",
            "minecraftWorlds",
        ]
        return candidates
            .map { root.appendingPathComponent($0) }
            .first { isDirectory($0) }
    }

    private static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    // フォルダの中から、使う写真を選んで読む
    private static func readPhoto(in folder: URL) -> Data? {
        guard let photoURL = photoURL(in: folder),
            let data = try? Data(contentsOf: photoURL),
            data.count <= maxPhotoBytes
        else { return nil }
        return data
    }

    // 使う写真の場所
    // 1. screenshot_icon_数字 の中で、数字がいちばん大きいもの（マイクラのカメラで撮りなおすと、数字が増える）
    // 2. なければ world_icon
    private static func photoURL(in folder: URL) -> URL? {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        let imageExtensions: Set<String> = ["jpeg", "jpg", "png"]

        var bestName: String?
        var bestNumber = Int.min
        for name in names {
            let fileURL = URL(fileURLWithPath: name)
            guard imageExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }
            let stem = fileURL.deletingPathExtension().lastPathComponent  // 拡張子を取った名前
            guard stem.hasPrefix("screenshot_icon") else { continue }

            // 「screenshot_icon」のあとの数字を取り出す（数字でない部分は無視。数字がなければ -1）
            let rest = stem.dropFirst("screenshot_icon".count)
            let digits = rest.drop { !$0.isNumber }.prefix { $0.isNumber }
            let number = Int(digits) ?? -1

            if number > bestNumber {
                bestNumber = number
                bestName = name
            }
        }
        if let bestName {
            return folder.appendingPathComponent(bestName)
        }

        for name in ["world_icon.jpeg", "world_icon.jpg", "world_icon.png"] where names.contains(name) {
            return folder.appendingPathComponent(name)
        }
        return nil
    }
}
