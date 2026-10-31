import SwiftUI

// 初回設定のステップ
enum OnboardingStep {
    case device
    case textInput
}

// 初回設定：機種選択 → 名前と自己紹介の2画面を切り替えて、最後に保存する
struct OnboardingView: View {
    let authViewModel: AuthViewModel
    @State private var step: OnboardingStep = .device  // 今のステップ
    @State private var selectedDevice: Device?  // 選んだ機種
    @State private var name: String = ""  // 入力された名前
    @State private var bio: String = ""  // 入力された自己紹介
    
    // 決定が押されたら：入力をととのえて保存する
    private func complete() {
        // 機種を取り出す（選ばれていなければ何もしない）
        guard let selectedDevice else { return }
        // 名前の前後の空白を取り除く
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // 自己紹介の前後の空白を取り除き、空なら nil にする
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        let bioToSave: String? = trimmedBio.isEmpty ? nil : trimmedBio
        // 保存する（成功すると AuthViewModel が state を signedIn にしてホームへ進む）
        Task {
            await authViewModel.completeOnboarding(
                name: trimmedName,
                device: selectedDevice,
                bio: bioToSave
            )
        }
    }
    
    var body: some View {
        VStack{
            switch step {
            case .device:
                // 機種を選んだら、名前と自己紹介へ
                DeviceStepView(selectedDevice: $selectedDevice) {
                    step = .textInput
                }
            case .textInput:
                TextInputStepView(
                    name: $name,
                    bio: $bio,
                    isSaving: authViewModel.isSaving,
                    complete: { complete() },  // 決定で保存
                    onBack: { step = .device }  // 機種選択へ戻る
                )
            }
            // 保存に失敗したときのエラー（場所を常に確保して、レイアウトがずれないようにする）
            Text(authViewModel.errorMessage ?? "")  // エラーが無いときは空の文字
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .top)  // 高さ 48 は常に確保する
        }
    }
}

#Preview {
    OnboardingView(
        authViewModel: AuthViewModel(repository: PreviewUserRepository())
    )
}
