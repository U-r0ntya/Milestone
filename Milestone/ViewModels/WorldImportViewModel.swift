import Foundation
import Observation

// ワールドの登録の ViewModel
// 「Minecraft」フォルダを読みこむ → 見つかったワールドを並べる → 選んだものを Firestore に保存する
// 写真はサーバーに上げず、端末の中だけに保存する（WorldPhotoStore）
@Observable
@MainActor
final class WorldImportViewModel {
    // 見つかったワールドの1つ
    struct Candidate: Identifiable {
        let world: World
        let photo: Data?  // ワールドの写真（なければ nil）
        var isRegistered: Bool  // すでに登録してあるか
        var id: String { world.folderName ?? world.id }  // フォルダ名で見分ける
    }

    // 見つかったワールド（最近遊んだ順）。まだ読みこんでいなければ空
    var candidates: [Candidate] = []
    // 登録するものとして選んでいるワールド（Candidate の id）
    var selectedIds: Set<String> = []
    // 登録中か
    var isSaving: Bool = false
    // 失敗したときに出す文
    var errorMessage: String? = nil
    // 全部登録できたか（画面を閉じる合図）
    var isSaved: Bool = false
    // 登録できた数（一部だけ失敗したときも、一覧を読みなおすのに使う）
    var savedCount: Int = 0
    // 選んだ Minecraft フォルダの場所
    private var pickedURL: URL?
    // すでに登録してあるワールド（一覧から受け取る）
    private let existingWorlds: [World]

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

    // 選んでいて、まだ登録していないワールド
    var selectedCandidates: [Candidate] {
        candidates.filter { selectedIds.contains($0.id) && !$0.isRegistered }
    }

    // まだ登録していないワールドがあるか
    var hasUnregistered: Bool {
        candidates.contains { !$0.isRegistered }
    }

    // まだ登録していないワールドを、全部選んでいるか
    var isAllSelected: Bool {
        candidates.filter { !$0.isRegistered }.allSatisfy { selectedIds.contains($0.id) }
    }

    // 1つのワールドの選ぶ・外すを切りかえる（登録済みは選べない）
    func toggle(_ candidate: Candidate) {
        guard !candidate.isRegistered else { return }
        if selectedIds.contains(candidate.id) {
            selectedIds.remove(candidate.id)
        } else {
            selectedIds.insert(candidate.id)
        }
    }

    // まだ登録していないワールドを、全部選ぶ（全部選んでいれば、全部外す）
    func toggleAll() {
        if isAllSelected {
            selectedIds.removeAll()
        } else {
            selectedIds = Set(candidates.filter { !$0.isRegistered }.map(\.id))
        }
    }

    // Minecraft フォルダを読みこんで、ワールドを並べる
    func importMinecraftFolder(from url: URL, ownerId: String, device: Device) {
        errorMessage = nil

        let results: [WorldFolderReader.Result]
        do {
            results = try WorldFolderReader.readAll(from: url)
        } catch {
            errorMessage = "ワールドが見つかりませんでした。「Minecraft」フォルダを選んでいるか、確かめてください。"
            return
        }

        // 1つずつ World にする（Data → NBTReader で辞書にする → LevelDatParser で World にする）
        // 読めなかったワールドは飛ばす
        var found: [Candidate] = []
        for result in results {
            guard let root = try? NBTReader.readLevelDat(result.levelDat),
                var world = try? LevelDatParser.parse(root, ownerId: ownerId, device: device)
            else { continue }
            world.folderName = result.folderName
            let isRegistered = existingWorlds.contains { $0.folderName == result.folderName }
            found.append(Candidate(world: world, photo: result.photo, isRegistered: isRegistered))
        }

        guard !found.isEmpty else {
            candidates = []
            errorMessage = "ワールドが見つかりませんでした。「Minecraft」フォルダを選んでいるか、確かめてください。"
            return
        }

        // 最近遊んだ順に並べて、まだ登録していないものを最初から選んでおく
        candidates = found.sorted {
            ($0.world.lastPlayed ?? .distantPast) > ($1.world.lastPlayed ?? .distantPast)
        }
        selectedIds = Set(candidates.filter { !$0.isRegistered }.map(\.id))
        pickedURL = url
    }

    // 選んだワールドを登録する
    func save() async {
        let targets = selectedCandidates
        guard !targets.isEmpty, !isSaving else { return }
        errorMessage = nil
        isSaving = true  // 登録を始めた。抜けるときに必ず false に戻す
        defer { isSaving = false }

        // Minecraft フォルダの場所を覚えておく（全部の更新で、選びなおさずに読めるように）
        if let pickedURL, pickedURL.startAccessingSecurityScopedResource() {
            MinecraftFolderStore.save(pickedURL)
            pickedURL.stopAccessingSecurityScopedResource()
        }

        // 1つずつ保存する。保存できたものは「登録済み」にして、選ぶのをやめる
        var failedCount = 0
        for target in targets {
            do {
                try await repository.saveWorld(target.world)
                if let photo = target.photo {
                    WorldPhotoStore.shared.save(photo, for: target.world.id)  // 写真は端末の中だけ
                }
                if let index = candidates.firstIndex(where: { $0.id == target.id }) {
                    candidates[index].isRegistered = true
                }
                selectedIds.remove(target.id)
                savedCount += 1
            } catch {
                failedCount += 1
            }
        }

        if failedCount == 0 {
            isSaved = true
        } else {
            errorMessage = "\(failedCount) 件のワールドを保存できませんでした。通信状態を確かめて、もう一度試してください。"
        }
    }
}
