import SwiftUI

// 画面の真ん中に出す「下書きを保存しますか？」（色付きのガラスのカード）
struct DraftSaveDialog: View {
    let onSave: () -> Void  // 「下書きを保存」を押したときの処理（親が決める）
    let onDelete: () -> Void  // 「削除」を押したときの処理（親が決める）

    var body: some View {
        ZStack {
            // 後ろを暗くする（どちらかを選ぶまで、後ろの画面はさわれない）
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // タイトルと説明
                VStack(spacing: 8) {
                    Text("下書きを保存しますか？")
                        .font(.title3).bold().foregroundStyle(.appTextPrimary)
                    Text("次に開いたとき、続きから書けます")
                        .font(.footnote)
                        .foregroundStyle(.appTextSecondary)
                        .multilineTextAlignment(.center)
                }

                // ボタン
                VStack(spacing: 12) {
                    Button {
                        onSave()
                    } label: {
                        Text("下書きを保存")
                            .frame(maxWidth: 200)
                    }
                    .buttonStyle(.primary)

                    Button {
                        onDelete()
                    } label: {
                        Text("削除")
                            .foregroundStyle(.red)  // 取り消せない操作なので赤い文字
                            .frame(maxWidth: 200)
                    }
                    .buttonStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: 280)
            // ガラスのカード。アプリのカードの色を混ぜて、後ろが透けすぎないようにする
            .glassEffect(
                .regular.tint(Color.appCard.opacity(0.7)),
                in: .rect(cornerRadius: 28)
            )
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        Text("後ろの画面")
        DraftSaveDialog(onSave: {}, onDelete: {})
    }
}
