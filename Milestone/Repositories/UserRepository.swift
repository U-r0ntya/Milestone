import FirebaseFirestore

protocol UserRepository {
    func fetchUser(uid: String) async throws -> User?
    func saveUser(_ user: User) async throws
}

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
        // あった   → User に変換して返す（登録済みの人）
        let user = try snapshot.data(as: User.self)
        return user
    }

    func saveUser(_ user: User) async throws {
        // 1. 場所を決める
        let ref = db.collection("users").document(user.id)
        // 2. 書く
        try ref.setData(from: user)
    }
}
