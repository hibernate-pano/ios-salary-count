import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(
            image: "dollarsign.circle",
            title: "实时工资计算",
            description: "精确计算你的每一秒工作收入，让时间更有价值"
        ),
        OnboardingPage(
            image: "calendar",
            title: "智能节假日",
            description: "自动同步国家法定节假日，准确计算工作日"
        ),
        OnboardingPage(
            image: "chart.bar",
            title: "多维度统计",
            description: "今日、本月、年度收入统计，清晰展示收入情况"
        ),
        OnboardingPage(
            image: "widget",
            title: "桌面小组件",
            description: "支持小、中、大三种尺寸，随时查看收入情况"
        )
    ]
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(pages.indices, id: \.self) { index in
                VStack(spacing: 20) {
                    Image(systemName: pages[index].image)
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding(.top, 60)
                    
                    Text(pages[index].title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(pages[index].description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    if index == pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                isPresented = false
                            }
                        }) {
                            Text("开始使用")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 200, height: 50)
                                .background(Color.blue)
                                .cornerRadius(25)
                        }
                        .padding(.top, 40)
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
} 