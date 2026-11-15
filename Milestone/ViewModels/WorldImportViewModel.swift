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

    // ワールドを保存する係
    private let repository: WorldRepository

    init() {
        self.repository = FirestoreWorldRepository()
    }
    init(repository: WorldRepository) {
        self.repository = repository
    }

    // level.dat を読みこんで World を作る
    func importLevelDat(from url: URL, ownerId: String, device: Device) {
        errorMessage = nil
        // ファイルを読む許可を取る
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "このファイルを読みこめませんでした。level.dat を選んでいるか、確かめてください。"
            return
        }
        guard url.lastPathComponent == "level.dat" else {
            errorMessage = "このファイルを読みこめませんでした。level.dat を選んでいるか、確かめてください。"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }  // この関数を抜けるときに、必ず読み終わりを伝える
        // Data にする → NBTReader で辞書にする → LevelDatParser で World にする → world に入れる
        do {
            let data = try Data(contentsOf: url)
            let root = try NBTReader.readLevelDat(data)
            world = try LevelDatParser.parse(
                root,
                ownerId: ownerId,
                device: device
            )
        } catch {
            errorMessage = "このファイルを読みこめませんでした。level.dat を選んでいるか、確かめてください。"  //  失敗したら
        }
    }

    // 読みこんだワールドを登録する
    func save() async {
        errorMessage = nil
        // 読みこんだワールドがなければ、何もしない
        guard let world else { return }
        // 登録中にもう一度呼ばれたら、何もしない
        guard isSaving == false else { return }
        // 登録を始めた。抜けるときに必ず false に戻す
        isSaving = true
        defer { isSaving = false }
        // repository.saveWorld で保存する。成功したら isSaved = true
        do {
            try await repository.saveWorld(world)
            isSaved = true
        } catch {
            errorMessage = "ワールドを保存できませんでした。通信状態を確かめて、もう一度試してください。"
        }
    }
}
