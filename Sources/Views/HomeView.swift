import SwiftUI

/// 货币格式化（人民币，两位小数）。
private let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "CNY"
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter
}()

func formatCurrency(_ value: Double) -> String {
    currencyFormatter.string(from: NSNumber(value: value)) ?? "¥0.00"
}

/// 每秒工资可能很小（如 ¥0.005），用 4 位小数避免显示成 0。
func formatPerSecond(_ value: Double) -> String {
    String(format: "¥%.4f", value)
}

/// 实时跳动主页。
struct HomeView: View {
    @EnvironmentObject private var store: SalaryStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    statusBadge
                    todayHero
                    HStack(spacing: 16) {
                        StatCard(title: "本月累计", amount: store.monthEarnings)
                        StatCard(title: "年度累计", amount: store.yearEarnings)
                    }
                }
                .padding()
            }
            .navigationTitle("我的收入")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: store.isWorkdayToday ? "briefcase.fill" : "cup.and.saucer.fill")
            Text(store.isWorkdayToday ? "今天是工作日" : "今天是休息日")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var todayHero: some View {
        VStack(spacing: 12) {
            Text("今日已赚")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(formatCurrency(store.todayEarnings))
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.tint)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("每秒 +\(formatPerSecond(store.engine.salaryPerSecond(now: store.now)))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

/// 统计卡片。
struct StatCard: View {
    let title: String
    let amount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(formatCurrency(amount))
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    HomeView()
        .environmentObject(SalaryStore())
}
