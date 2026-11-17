import Foundation
import Observation

// ワールドの登録の ViewModel（level.dat を読みこんで、Firestore に保存する）
@Observable
@MainActor
final class WorldImportViewModel {
    // 画面が見る値（上の表の 5 つ）
    // 読みこめたワールド。まだなら nil
    var world: World? = nil
    // 読みこみ中か
    var isLoading: Bool = false
    // 登録中か
    var isSaving: Bool = false
    // 失敗したときに出す文
    var errorMessage: String? = nil
    // 登録が終わったか（画面を閉じる合図）
    var isSaved: Bool = false
    // URLを保管
    private var pickedURL: URL?
    // すでに登録してあるワールド（一覧から受け取る）
    private let existingWorlds: [World]

    // 読みこんだワールドが、すでに登録してあるか
    var isDuplicate: Bool {
        // 読みこんだワールドのフォルダ名を取り出す（なければ false）
        guard let folderName = world?.folderName else { return false }
        // existingWorlds の中に、同じフォルダ名のものがあれば true
        return existingWorlds.contains { $0.folderName == folderName }
    }

    // ワールドを保存する係
    private let repository: WorldRepository

    init(existingWorlds: [World]) {
        self.repository = FirestoreWorldRepository()
        self.existingWorlds = existingWorlds
    }
    init(repository: WorldRepository, existingWorlds: [World]) {
        self.repository = repository
        self.existingWorlds = existingWorlds
    }

    // level.dat を読みこんで World を作る
    func importLevelDat(from url: URL, ownerId: String, device: Device) {
        errorMessage = nil
        guard url.lastPathComponent == "level.dat" else {
            errorMessage = "このファイルを読みこめませんでした。level.dat を選んでいるか、確かめてください。"
            return
        }
        // ファイルを読む許可を取る
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "このファイルを読みこめませんでした。level.dat を選んでいるか、確かめてください。"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }  // この関数を抜けるときに、必ず読み終わりを伝える
        // Data にする → NBTReader で辞書にする → LevelDatParser で World にする → world に入れる
        do {
            let data = try Data(contentsOf: url)
            let root = try NBTReader.readLevelDat(data)
            var world = try LevelDatParser.parse(
                root,
                ownerId: ownerId,
                device: device
            )
            world.folderName = url.deletingLastPathComponent().lastPathComponent
            self.world = world  // worldを保管
            pickedURL = url  // URLを保管しておく
        } catch {
            errorMessage = "このファイルを読みこめませんでした。level.dat を選んでいるか、確かめてください。"  //  失敗したら
        }
    }

    // 読みこんだワールドを登録する
    func save() async {
        // すでに読み込んであるワールドか（あれば何もしない）
        guard !isDuplicate else { return }
        // 読みこんだワールドがなければ、何もしない
        guard let world else { return }
        // 登録中にもう一度呼ばれたら、何もしない
        guard !isSaving else { return }
        errorMessage = nil
        // 登録を始めた。抜けるときに必ず false に戻す
        isSaving = true
        defer { isSaving = false }
        // repository.saveWorld で保存する。成功したら isSaved = true
        do {
            try await repository.saveWorld(world)
            if let pickedURL, pickedURL.startAccessingSecurityScopedResource() {
                defer { pickedURL.stopAccessingSecurityScopedResource() }
                LevelDatBookmarkStore.save(pickedURL, for: world.id)
            }
            isSaved = true
        } catch {
            errorMessage = "ワールドを保存できませんでした。通信状態を確かめて、もう一度試してください。"
        }
    }
}
