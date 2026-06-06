import SwiftUI

/// 设置页：月薪、工时、午休、工作日。改动即存（由 SalaryStore.didSet 落盘）。
struct SettingsView: View {
    @EnvironmentObject private var store: SalaryStore
    @EnvironmentObject private var themeStore: ThemeStore

    /// 月薪输入框的聚焦状态，用于收起数字键盘。
    @FocusState private var salaryFocused: Bool

    /// weekday 1...7 与中文名的对应（1 = 周日）。
    private let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

    var body: some View {
        NavigationStack {
            Form {
                salarySection
                appearanceSection
                // 全天模式下无需工时/工作日设置，隐藏
                if store.config.earningMode == .workHours {
                    workTimeSection
                    lunchSection
                    workDaysSection
                }
                aboutSection
            }
            .navigationTitle("设置")
            .scrollDismissesKeyboard(.interactively)   // 下滑表单即可收起键盘
            .modifier(SettingsHaptics(
                accent: themeStore.accent,
                appearance: themeStore.appearance,
                workDays: store.config.workDays,
                lunchEnabled: store.config.lunchEnabled
            ))
            .toolbar {
                // 数字键盘上方的「完成」按钮
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { salaryFocused = false }
                }
            }
        }
    }

    private var salarySection: some View {
        Section {
            HStack {
                Text("月薪")
                Spacer()
                TextField("月薪", value: $store.config.monthlySalary, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($salaryFocused)
                Text("元")
                    .foregroundStyle(.secondary)
            }

            // 计薪模式
            Picker("计薪模式", selection: $store.config.earningMode.animation()) {
                ForEach(EarningMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            // 模式说明
            Text(store.config.earningMode.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("工资")
        } footer: {
            Text("两种模式只是把月薪摊到不同的时间里：工作时段模式钱集中在上班时段、单位时间更高；全天模式 24 小时细水长流、单位时间较低。同一时刻数字不同是正常的，到月底累计总额一致。")
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

    /// 外观设置：配色主题 + 明暗模式。
    private var appearanceSection: some View {
        Section("外观") {
            // 配色色板
            VStack(alignment: .leading, spacing: 10) {
                Text("主题色")
                    .font(.subheadline)
                HStack(spacing: 14) {
                    ForEach(AccentTheme.allCases) { theme in
                        Button {
                            themeStore.accent = theme
                        } label: {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [theme.primary, theme.secondary],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle().strokeBorder(.primary,
                                        lineWidth: themeStore.accent == theme ? 2.5 : 0)
                                )
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .opacity(themeStore.accent == theme ? 1 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }
            .padding(.vertical, 4)

            // 明暗模式
            Picker("外观模式", selection: Binding(
                get: { themeStore.appearance },
                set: { themeStore.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
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

/// 设置页触感反馈（iOS 17+ 生效；iOS 16 无触感但不影响功能）。
private struct SettingsHaptics: ViewModifier {
    let accent: AccentTheme
    let appearance: AppearanceMode
    let workDays: Set<Int>
    let lunchEnabled: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .sensoryFeedback(.selection, trigger: accent)
                .sensoryFeedback(.selection, trigger: appearance)
                .sensoryFeedback(.selection, trigger: workDays)
                .sensoryFeedback(.impact(weight: .light), trigger: lunchEnabled)
        } else {
            content
        }
    }
}
