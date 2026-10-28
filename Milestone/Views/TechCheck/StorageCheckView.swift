import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage

// 技術検証用：写真を選んで Storage に上げ、URL から表示できるか確かめる（確かめたら消す）
struct StorageCheckView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var uploadedURL: URL?
    @State private var isUploading = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                PhotosPicker("写真を選ぶ", selection: $selectedItem, matching: .images)

                if isUploading {
                    ProgressView("アップロード中…")
                }

                if let message {
                    Text(message)
                        .font(.caption)
                }

                if let uploadedURL {
                    // もらった URL から、もう一度ダウンロードして表示する
                    AsyncImage(url: uploadedURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxHeight: 300)
                }
            }
            .padding()
            .navigationTitle("Storage（検証）")
            // 写真が選ばれたら、アップロードを始める
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task { await upload(newItem) }
            }
        }
    }

    private func upload(_ item: PhotosPickerItem) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            message = "ログインしていません"
            return
        }
        isUploading = true
        message = nil
        uploadedURL = nil
        defer { isUploading = false }   // 成功しても失敗しても、最後に false に戻す

        do {
            // 1. 選んだ写真を読み込んで、小さくしてから JPEG にする
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpeg = image.resizedForUpload(maxSide: 1280).jpegData(compressionQuality: 0.7) else {
                message = "写真を読み込めませんでした"
                return
            }

            // 2. 置き場所を決める（posts/自分のuid/ランダムな名前.jpg）
            let ref = Storage.storage().reference()
                .child("posts/\(uid)/\(UUID().uuidString).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            // 3. アップロードして、表示用の URL をもらう
            _ = try await ref.putDataAsync(jpeg, metadata: metadata)
            uploadedURL = try await ref.downloadURL()
            message = "成功：\(jpeg.count / 1024) KB をアップロードした"
        } catch {
            message = "失敗：\(error.localizedDescription)"
        }
    }
}

extension UIImage {
    // 長い辺が maxSide を超えていたら、縦横の比率を保ったまま小さくする
    func resizedForUpload(maxSide: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return self }

        let scale = maxSide / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1   // 画面の倍率をかけずに、そのままのピクセル数にする
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
