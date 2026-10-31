import SwiftUI

// 初回設定 名前と自己紹介を入れる
struct TextInputStepView: View {
    @Binding var name: String
    @Binding var bio: String
    let isSaving: Bool   // 保存中かどうか（親から受け取る）
    // 入力欄にすぐカーソルを置く
    @FocusState private var isFocused: Bool
    let complete: () -> Void
    let onBack: () -> Void
    
    

    // 最大文字数
    private let nameMaxLength = 20
    private let bioMaxLength = 150

    // 前後の空白を取り除いた名前
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // 前後の空白を取り除いた自己紹介
    private var trimmedBio: String {
        bio.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    // 決定を押せるかどうか
    private var canGoNext: Bool {
        // 名前は空でなく上限以下、自己紹介は上限以下（空でもOK）
        return !trimmedName.isEmpty && trimmedName.count <= nameMaxLength
            && trimmedBio.count <= bioMaxLength
    }

    var body: some View {
        VStack(spacing: 0) {
            // 名前の見出し
            StepHeader(
                stepNumber: 2,
                title: "ニックネームを決めよう",
                subtitle: "アプリで表示される名前です。\n本名は入れないでください。(\(nameMaxLength)文字まで)"
            )
            .padding(.bottom, 16)
            // 名前の入力欄
            TextField("名前", text: $name)
                .padding(.leading, 16)
                .focused($isFocused)
                .onAppear { isFocused = true }  // 画面が出たらすぐキーボードを出す
                .foregroundStyle(.primary).bold()
                .font(.system(size: 24))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(Color.gray.opacity(0.2))
                .clipShape(Capsule())
                .padding(.horizontal, 24)
            // 名前の注意書き（上限を超えたらエラーに変わる）
            VStack(alignment: .leading) {
                Text(
                    trimmedName.count > nameMaxLength
                        ? "文字数が\(nameMaxLength)文字を超えています" : "※必須"
                )
                .font(.footnote)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
                .padding(.horizontal, 36)

            }
            .padding(.bottom, 32)
            // 自己紹介の見出し
            StepHeader(
                stepNumber: nil,
                title: "自己紹介を書こう",
                subtitle: "好きな遊び方や建築のことなど。あとで書いてもOK"
            )

            // 自己紹介の入力欄（日本語の変換確定で文字が消えないよう TextEditor を使う）
            ZStack(alignment: .topLeading) {
                TextEditor(text: $bio)
                    .scrollContentBackground(.hidden)  // 標準の白い背景を消す
                    .font(.system(size: 18, weight: .bold))
                    .frame(height: 120)  // 5行くらいの高さ
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                // TextEditor には薄い文字が無いので、空のときだけ自分で表示する
                if bio.isEmpty {
                    Text("サバイバルでのんびり遊んでいます")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)  // この文字をタップしても入力欄に届くように
                }
            }
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            // 自己紹介の文字数（上限を超えたら赤）
            VStack(alignment: .leading) {
                Text(
                    trimmedBio.count > bioMaxLength
                        ? "\(trimmedBio.count)/\(bioMaxLength)文字 文字数オーバーです"
                        : "\(trimmedBio.count)/\(bioMaxLength)文字"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
                .padding(.horizontal, 36)
                .font(.subheadline)
                .foregroundStyle(
                    trimmedBio.count > bioMaxLength ? Color.red : Color.secondary
                )  // 超えたら赤
            }
            .padding(.bottom, 32)
            // 戻るボタンと決定ボタン（決定は入力が条件を満たすまで押せない）
            HStack {
                // 戻るボタン
                Button {
                    onBack()
                } label: {
                    Text("戻る")
                        .foregroundStyle(.white).bold()
                        .font(.system(size: 24))
                        .frame(width: 120, height: 48)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                .padding(.leading, 24)
                Spacer()
                // 決定ボタン
                Button {
                    complete()
                } label: {
                    Group {
                        if isSaving {
                            ProgressView()            // 保存中はくるくる
                                .tint(.white)
                        } else {
                            Text("決定")
                                .foregroundStyle(.white).bold()
                                .font(.system(size: 24))
                        }
                    }
                    .frame(width: 120, height: 48)
                    .background(!canGoNext || isSaving ? Color.gray.opacity(0.2) : Color.accentColor)
                    .clipShape(Capsule())
                }
                .disabled(!canGoNext || isSaving)     // 入力が足りないとき、または保存中は押せない
                .padding(.trailing, 24)

            }
        }
    }
}

#Preview {
    @Previewable @State var name = ""
    @Previewable @State var bio = ""
    TextInputStepView(name: $name, bio: $bio,isSaving: false, complete: {}, onBack: {})
}
