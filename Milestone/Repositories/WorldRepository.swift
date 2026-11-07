import FirebaseFirestore
import Foundation

// ワールドを読み書きする係の約束（Firestore 版とプレビュー用の Mock 版がある）
protocol WorldRepository {
    /// 持ち主（ownerId）のワールドを全部読んで、新しく登録した順に返す
    func fetchWorlds(ownerId: String) async throws -> [World]
    /// ワールドを保存する（登録にも、直したあとの保存にも使う。同じ ID の場所に上書きする）
    func saveWorld(_ world: World) async throws
    /// ワールドを消す
    func deleteWorld(id: String) async throws
}

// プレビュー用の係（Firestore を使わず、見本のワールドを返す）
struct MockWorldRepository: WorldRepository {
    // 見本のワールドを2つ返す（新しく登録した順）
    func fetchWorlds(ownerId: String) async throws -> [World] {
        [
            World(
                id: "preview-world-1",
                ownerId: ownerId,
                device: .nintendoSwitch,
                createdAt: Date().addingTimeInterval(-1 * 24 * 60 * 60),  // 1日前
                name: "サバイバル1",
                seed: -1_234_567_890_123,
                gameMode: .survival,
                difficulty: .normal,
                spawnPoint: BlockPosition(x: 0, y: 64, z: 0),
                lastOpenedVersion: "1.21.40",
                lastPlayed: Date().addingTimeInterval(-3 * 60 * 60),  // 3時間前
                time: 2_400_000_00,
                worldType: .infinite,
                commandsEnabled: false,
                hasUsedCheats: false,
                isMultiplayer: true,
                texturePacksRequired: false,
                playerPermission: .member
            ),
            // 手で入力した場合の例（必須の項目だけ）
            World(
                id: "preview-world-2",
                ownerId: ownerId,
                device: .nintendoSwitch,
                createdAt: Date().addingTimeInterval(-7 * 24 * 60 * 60),  // 7日前
                name: "建築用クリエイティブ",
                seed: nil,
                gameMode: .creative,
                difficulty: nil,
                spawnPoint: nil,
                lastOpenedVersion: nil,
                lastPlayed: nil,
                time: nil,
                worldType: nil,
                commandsEnabled: true,
                hasUsedCheats: nil,
                isMultiplayer: true,
                texturePacksRequired: nil,
                playerPermission: nil
            ),
        ]
    }

    func saveWorld(_ world: World) async throws {
        // Mock は保存しない
    }

    func deleteWorld(id: String) async throws {
        // Mock は消さない
    }
}

// Firestore で読み書きする係
struct FirestoreWorldRepository: WorldRepository {
    let db = Firestore.firestore()

    // 指定の ID の人（持ち主）のワールドを全部読んで、配列で返す
    func fetchWorlds(ownerId: String) async throws -> [World] {
        // - whereField("ownerId", isEqualTo: ownerId)：「ownerId フィールドが、引数の ownerId と同じもの」という条件を作る（通信しない。Query を返す）
        // - getDocuments()：その条件に合うドキュメントを、Firestore に読みに行く（通信する。QuerySnapshot を返す）
        // ルールで本人のワールドしか読めないので、この絞りこみがないと読みこみ全体がエラーになる
        let snapshot = try await db.collection("worlds")
            .whereField("ownerId", isEqualTo: ownerId).getDocuments()

        // 1件ずつ World に変える
        let fetchedWorlds = try snapshot.documents.map {
            try $0.data(as: World.self)
        }
        // 新しく登録した順に並べて返す（order(by:) は whereField と一緒に使うとインデックスがいるので、アプリで並べる）
        return fetchedWorlds.sorted { $0.createdAt > $1.createdAt }
    }

    // ワールドを保存する（なければ作り、あれば上書きする）
    func saveWorld(_ world: World) async throws {
        // 場所を決める（worlds の中の、このワールドの ID のドキュメント。通信しない）
        let ref = db.collection("worlds").document(world.id)
        // その場所に、World の中身を書く
        try ref.setData(from: world)
    }

    // ワールドを消す
    func deleteWorld(id: String) async throws {
        // 場所.delete() で、その場所のドキュメントを消せる（通信する）
        try await db.collection("worlds").document(id).delete()
    }
}
