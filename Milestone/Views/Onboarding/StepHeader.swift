import SwiftUI

// 初回設定の各ステップの見出し
struct StepHeader: View {
    let stepNumber: Int?     // 何ステップ目か（nil なら表示しない）
    let title: String       // タイトル
    let subtitle: String?    // 説明文（nil なら表示しない）

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let stepNumber {
                Text("ステップ \(stepNumber) / 2")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.tint)
            }
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.appTextPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 24)
        .padding(.bottom, 12)
    }
}

#Preview {
    StepHeader(stepNumber: 1, title: "どの機種で遊んでる？", subtitle: "マイクラをプレイしている機種を選んでください")
}
