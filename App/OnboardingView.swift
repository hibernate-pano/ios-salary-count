import SwiftUI

/// 首次启动引导页。3 页讲清产品是什么，文案如实反映「实时工资计数器」定位。
struct OnboardingView: View {
    /// 完成引导的回调（由父视图持久化标记）。
    var onFinish: () -> Void

    @State private var currentPage = 0

    private struct Page: Identifiable {
        let id = UUID()
        let image: String
        let title: String
        let description: String
    }

    private let pages = [
        Page(
            image: "dollarsign.circle.fill",
            title: "看着工资实时增长",
            description: "上班时间里，你赚的每一秒都在屏幕上跳动"
        ),
        Page(
            image: "slider.horizontal.3",
            title: "几步完成设置",
            description: "填上月薪和上下班时间，剩下的交给它"
        ),
        Page(
            image: "rectangle.3.group.fill",
            title: "今日 · 本月 · 年度",
            description: "主屏小组件随时一眼看到你赚了多少"
        )
    ]

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: 24) {
                        Image(systemName: pages[index].image)
                            .font(.system(size: 80))
                            .foregroundStyle(.tint)
                            .padding(.top, 80)

                        Text(pages[index].title)
                            .font(.title.bold())

                        Text(pages[index].description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 40)

                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(action: advance) {
                Text(currentPage < pages.count - 1 ? "下一步" : "开始使用")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    private func advance() {
        if currentPage < pages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            onFinish()
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
