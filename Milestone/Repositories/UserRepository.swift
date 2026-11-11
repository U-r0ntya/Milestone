import FirebaseFirestore

// ユーザーを読み書きする係の約束（Firestore 版とプレビュー用がある）
protocol UserRepository {
    /// uid の人を読む（まだ登録していない人なら nil）
    func fetchUser(uid: String) async throws -> User?
    /// ユーザーを保存する（ドキュメント全体を書く）
    func saveUser(_ user: User) async throws
    /// お気に入りのワールドだけを書きかえる（worldId が nil なら、お気に入りを外す）
    func updateFavoriteWorld(userId: String, worldId: String?) async throws
}

// プレビュー用の係（通信しない。Firestore を使わず、何も返さない・保存しない）
struct MockUserRepository: UserRepository {
    func fetchUser(uid: String) async throws -> User? { nil }
    func saveUser(_ user: User) async throws {}
    func updateFavoriteWorld(userId: String, worldId: String?) async throws {}  // プレビューでは保存しない
}

// Firestore で読み書きする係
struct FirestoreUserRepository: UserRepository {
    let db = Firestore.firestore()

    //例: uidが abc123 の人を探して」と頼まれる
    func fetchUser(uid: String) async throws -> User? {
        // users/abc123 という住所を決める
        let ref = db.collection("users").document(uid)
        // その住所を読みに行く
        let snapshot = try await ref.getDocument()
        // 無かった → nil を返す（まだ登録していない人）
        guard snapshot.exists else {
            return nil
        }
        // あれば User に変換して返す
        let user = try snapshot.data(as: User.self)
        return user
    }

    func saveUser(_ user: User) async throws {
        // 1. 場所を決める
        let ref = db.collection("users").document(user.id)
        // 2. 書く
        try ref.setData(from: user)
    }

    // お気に入りのワールドを保存する（ほかの項目はそのままで、favoriteWorldId だけ書きかえる）
    func updateFavoriteWorld(userId: String, worldId: String?) async throws {
        let ref = db.collection("users").document(userId)
        if let worldId {
            // お気に入りにする：ワールドの ID を入れる
            try await ref.updateData(["favoriteWorldId": worldId])
        } else {
            // お気に入りを外す：辞書に nil は入れられないので、FieldValue.delete() で項目ごと消す
            try await ref.updateData(["favoriteWorldId": FieldValue.delete()])
        }

    }
}
