import FirebaseFirestore

protocol UserRepository {
    func fetchUser(uid: String) async throws -> User?
    func saveUser(_ user: User) async throws
}

struct FirestoreUserRepository: UserRepository {
    let db = Firestore.firestore()

    func fetchUser(uid: String) async throws -> User? {
        // 1. 場所を決める
        let ref = db.collection("users").document(uid)
        // 2. 読む
        let snapshot = try await ref.getDocument()
        // 3. 無ければ nil を返す
        guard snapshot.exists else {
           return nil
        }
        // 4. あれば User に変換して返す
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
