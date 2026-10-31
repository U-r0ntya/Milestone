import SwiftUI

// 初回設定 機種を選ぶ
struct DeviceStepView: View {
    @Binding var selectedDevice: Device?   // 親の selectedDevice を借りる
    let onNext: () -> Void                 // 「次へ」が押されたときの処理（親が決める）

    var body: some View {
        VStack {
            VStack {
                Spacer()
                // 見出し
                StepHeader(stepNumber: 1, title: "どの機種で遊んでる？", subtitle: "マイクラをプレイしている機種を選んでください")

                // 機種の一覧
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
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(.tint)
                                    .opacity(selectedDevice == item ? 1 : 0)
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
                
                // 次へボタン（機種を選ぶまで押せない）
                HStack {
                    Spacer()
                    Button {
                        onNext() 
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
        }
    }
}

#Preview {
    @Previewable @State var device: Device? = nil   // プレビュー用の仮の値
    DeviceStepView(selectedDevice: $device) { }
}
