import SwiftUI

/// 设置页：月薪、工时、午休、工作日。改动即存（由 SalaryStore.didSet 落盘）。
struct SettingsView: View {
    @EnvironmentObject private var store: SalaryStore

    /// weekday 1...7 与中文名的对应（1 = 周日）。
    private let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

    var body: some View {
        NavigationStack {
            Form {
                salarySection
                workTimeSection
                lunchSection
                workDaysSection
                aboutSection
            }
            .navigationTitle("设置")
        }
    }

    private var salarySection: some View {
        Section("工资") {
            HStack {
                Text("月薪")
                Spacer()
                TextField("月薪", value: $store.config.monthlySalary, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("元")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var workTimeSection: some View {
        Section("工作时间") {
            DatePicker(
                "上班时间",
                selection: $store.config.workStartTime,
                displayedComponents: .hourAndMinute
            )
            DatePicker(
                "下班时间",
                selection: $store.config.workEndTime,
                displayedComponents: .hourAndMinute
            )
        }
    }

    private var lunchSection: some View {
        Section("午休") {
            Toggle("启用午休", isOn: $store.config.lunchEnabled.animation())
            if store.config.lunchEnabled {
                DatePicker(
                    "午休开始",
                    selection: $store.config.lunchStartTime,
                    displayedComponents: .hourAndMinute
                )
                DatePicker(
                    "午休结束",
                    selection: $store.config.lunchEndTime,
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    private var workDaysSection: some View {
        Section("工作日") {
            ForEach(1...7, id: \.self) { weekday in
                Toggle(weekdayNames[weekday - 1], isOn: bindingForWorkday(weekday))
            }
        }
    }

    private var aboutSection: some View {
        Section("关于") {
            HStack {
                Text("版本")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// 为某个 weekday 生成 Toggle 绑定。
    private func bindingForWorkday(_ weekday: Int) -> Binding<Bool> {
        Binding(
            get: { store.config.workDays.contains(weekday) },
            set: { isOn in
                if isOn {
                    store.config.workDays.insert(weekday)
                } else if store.config.workDays.count > 1 {
                    // 至少保留一个工作日，避免空集合导致收入恒为 0、Widget 无效空转
                    store.config.workDays.remove(weekday)
                }
            }
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(SalaryStore())
}
