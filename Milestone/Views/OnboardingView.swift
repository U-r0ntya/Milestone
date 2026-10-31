import SwiftUI

// 初回設定のステップ
enum OnboardingStep {
    case device
    case name
    case bio
}

struct OnboardingView: View {
    let authViewModel: AuthViewModel
    @State private var step: OnboardingStep = .device
    @State private var selectedDevice: Device?
    @State private var name: String = ""
    @State private var bio: String = ""
    var body: some View {
        VStack {
            // 3つの画面を出し分ける
            switch step {
            case .device:
                VStack {
                    Spacer()
                    // 見出し
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ステップ 1 / 3")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.tint)  // アプリカラー
                        Text("どの機種で遊んでる？")
                            .font(.system(size: 28, weight: .bold))
                        Text("マイクラをプレイしている機種を選んでください")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)  // 灰色
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)  // 左にそろえる
                    .padding(.bottom, 12)
                    .padding(.leading, 16)

                    // リスト
                    VStack(spacing: 0) {
                        ForEach(Device.allCases, id: \.self) { item in
                            Button {
                                selectedDevice = item  // 選んだ機種を覚える
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: item.iconName)
                                        .font(.title2)
                                        .frame(width: 36)  // アイコンの幅をそろえる
                                    Text(item.displayName)
                                    Spacer()
                                    if selectedDevice == item {  // 選んだ機種にはチェックを付ける
                                        Image(
                                            systemName: "checkmark.circle.fill"
                                        )
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundStyle(.tint)  // アプリカラー
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .contentShape(Rectangle())  // 行全体を押せるようにする
                            }
                            .foregroundStyle(.primary)  // ボタンの文字を青ではなく普通の色に

                            // 最後の行以外は、下に区切り線を引く
                            if item != Device.allCases.last {
                                Divider()
                            }
                        }
                    }
                    .background(Color(.systemBackground))  // 背景（ライトモードでは白）
                    .clipShape(RoundedRectangle(cornerRadius: 16))  // 角を丸く切り抜く
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)  // 枠線
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    // 次へボタン
                    HStack {
                        Spacer()
                        Button {
                            step = .name
                        } label: {
                            Text("次へ")
                                .foregroundStyle(.white).bold()
                                .font(.system(size: 24))
                                .frame(width: 120, height: 48)
                                .background(selectedDevice == nil ? Color.gray.opacity(0.4) : Color.accentColor)
                                .clipShape(Capsule())
                        }
                        .disabled(selectedDevice == nil)
                        .padding(.trailing, 24)
                    }
                    Spacer()
                }

            case .name:
                Text("名前の入力（作成中）")
                Button("戻る") { step = .device }
                Button("次へ") { step = .bio }
            case .bio:
                Text("自己紹介（作成中）")
                Button("戻る") { step = .name }
            }
            //    各画面に、仮の Text と「次へ」「戻る」ボタンを置いて、step を変える
        }
    }
}

#Preview {
    OnboardingView(
        authViewModel: AuthViewModel(repository: PreviewUserRepository())
    )
}
