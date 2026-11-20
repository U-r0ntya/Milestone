import Foundation
import Observation
import UIKit

// ワールドの写真を、端末の中だけに保存する係（サーバーには上げない）
// 保存先：アプリの Application Support/WorldPhotos/ワールドID
// 保存・削除すると revision が増えるので、写真を出している画面が描きなおされる
@Observable
final class WorldPhotoStore {
    static let shared = WorldPhotoStore()

    // 写真が変わった回数（画面に「変わった」と知らせるための数）
    private(set) var revision = 0

    // 一度読んだ写真を覚えておく（スクロールのたびにファイルを読まないため）
    @ObservationIgnored private var cache: [String: UIImage] = [:]
    // 写真がないとわかったワールド（何度もファイルを探さないため）
    @ObservationIgnored private var missing: Set<String> = []

    private init() {}

    // 写真を入れるフォルダ
    private var folder: URL {
        URL.applicationSupportDirectory.appending(path: "WorldPhotos", directoryHint: .isDirectory)
    }

    private func fileURL(for worldId: String) -> URL {
        folder.appending(path: worldId)
    }

    // ワールドの写真（なければ nil）
    func image(for worldId: String) -> UIImage? {
        _ = revision  // revision を読んでおくと、写真が変わったときに描きなおされる
        if let image = cache[worldId] { return image }
        if missing.contains(worldId) { return nil }
        if let data = try? Data(contentsOf: fileURL(for: worldId)),
            let image = UIImage(data: data)
        {
            cache[worldId] = image
            return image
        }
        missing.insert(worldId)
        return nil
    }

    // 写真を保存する（同じワールドの写真があれば、上書きする）
    func save(_ data: Data, for worldId: String) {
        guard let image = UIImage(data: data) else { return }  // 画像として読めないものは保存しない
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: fileURL(for: worldId), options: .atomic)
        } catch {
            return  // 保存できなくても、ワールドの登録は続ける（写真がないだけ）
        }
        cache[worldId] = image
        missing.remove(worldId)
        revision += 1
    }

    // 写真を消す（ワールドを削除したとき）
    func remove(for worldId: String) {
        try? FileManager.default.removeItem(at: fileURL(for: worldId))
        cache.removeValue(forKey: worldId)
        missing.insert(worldId)
        revision += 1
    }
}
