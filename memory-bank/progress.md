# 进度报告

## 当前状态（2026-06-06）

V2「实时工资计数器 + 桌面小组件」已完成并验证通过，可在 iPhone 模拟器运行。

## 演进历程

### V1：可运行骨架（tag v0.2）
从一个无法编译、装着虚假文档、堆满游离代码的半成品，重写成干净可跑的极简产品：
- 工程类型从错误的 SwiftPM library 改为 XcodeGen 生成的 App 工程
- 重写纯函数计算引擎 `SalaryEngine`，修复 weekday 约定 bug（1=周日…7=周六）
- `SalaryStore`（Timer 驱动每秒跳动）+ Codable/UserDefaults 持久化
- HomeView 实时主页 + SettingsView 设置
- 移除全部无法编译的旧碎片，16 个引擎单测通过

### V2：桌面小组件（tag v0.3）
- 三尺寸 Widget（进度环 + 金额母题），五状态自适应 + 未配置引导
- TimelineProvider：工作时段每 10 分钟真实快照 + 状态切换断点；非工作时段午夜重建
- App Group 共享配置（模拟器 ad-hoc 签名验证 entitlements 生效）
- 引擎重构：时间改用「自午夜分钟数」存储，脱离时区/夏令时
- 经 dynamic workflow 设计探索 + 多维度对抗性评审，修复 7 项确认问题
- 单测扩充至 23 个

### V2.1：汲取孪生项目理念（tag v0.3.1）
从同源项目 `salary-calculator` 汲取四项理念，按本项目架构（不引入 SwiftData）重新实现：
- 首次启动引导页 `OnboardingView`（3 页，UserDefaults 标记）
- 节假日接口雏形：`HolidayConfig`（Codable 值类型）+ `SalaryEngine.isWorkday(holidays:)`，判定优先级 调休补班 > 法定节假日 > 按星期几
- UI 测试 target（引导页→主界面/设置页走查 + 截图）
- memory-bank 文档体系

### V2.2：接入法定节假日数据（进行中）
- `HolidayData` 内置 2026 全年法定节假日 + 调休数据（来源：国务院办公厅通知）
- 数据流接入：`SalaryStore.engine` 和 Widget `SalaryEntry.make` 均带入当年节假日
- 主界面状态条显示节日名（如「春节 · 放假」「国庆调休 · 今天上班」），让用户明白为何不计薪
- 测试扩充至 32 单测 + 2 UI 测试（含 2026 春节/国庆/调休真实日期验证）

### V2.3：UI/UX 打磨 + App 图标 + 小组件升级（进行中）
- 建立共享设计语言 `Brand`（薄荷绿→青蓝品牌渐变、休息日暖橙渐变、字体/圆角规范），App 与 Widget 共用
- 主界面今日 hero 改为渐变卡片：大数字主角化、「每秒 +X」做成胶囊高亮、工作日绿/休息日橙双渐变 + 投影
- 统计卡加图标，AccentColor 统一为品牌主色
- App 图标：代码生成（`scripts/make_icon.swift`）渐变底 + ¥ + 上升趋势，接入 Assets
- 小组件图形从「进度环」升级为「液体填充」（财富蓄满隐喻）：圆形容器按进度从底部渐变填满 + 波浪顶边，套用品牌渐变；金额文字加背景投影保证可读性
- 视觉风格基调：生动渐变·有活力（用户选定）

### V2.4：小组件重做「赚钱感」（tag v0.6）
- 用户反馈进度环/液体填充「不像在赚钱」——根因：让「进度」当主角、金额成配角。方向纠正：金额绝对主角 + 财富色 + 增长动感
- 经三方案对比（黑金/金币/涨幅卡），用户选定「涨幅卡布局 + 金色数字」
- 小组件三尺寸重做：深蓝黑底 + 金色超大金额（主角）+ 右上涨幅徽章 + ↗每秒+¥ 增长提示 + 角落 ¥ 水印
- 质感升级：背景金色径向辉光、金额发光阴影、¥/小数小一号的主次字号、徽章细描边
- Brand 设计语言扩充财富主题色（widgetDarkBackground/goldGradient/gold/gain）

### V2.5：主题系统 + 预计年收入 + 真机测试（tag v0.7）
- 改 App 名「牛马薪水计算器」；收入页加「预计今年总收入」卡片（月薪×12 + 已赚进度）
- 设置页加「完成」键 + 下滑收起键盘（修复数字键盘无法收起）
- **主题系统**：配色（薄荷绿/鎏金/樱粉/海蓝）+ 明暗（跟随系统/浅色/深色）两独立维度，设置页「外观」区切换，@AppStorage 持久化
  - `AppTheme.swift`（AccentTheme/AppearanceMode/BrandTheme + 环境注入 `\.brand`）、`ThemeStore.swift`
  - HomeView 改用 `@Environment(\.brand)` 取色
- **小组件主题跟随**：放弃独立「金色+深底」，改为与主界面统一的主题渐变卡 + 白色金额；主题经 App Group 传给小组件（`accent_theme` 键）
- **真机测试**：免费个人账号自动签名装机（去 Widget/App Group，因免费账号不支持）；project.yml 有「device-only」与「含 Widget 模拟器验证」两套用法
- 删除未用的 CowMascot.swift（像素/小牛方向已放弃）
- 32 单测通过

### V2.6：体验打磨 + 全天计薪模式（tag v0.8）
- **体验打磨**：今日/本月/年度金额数字平滑滚动（iOS17+ numericText，iOS16 降级）；切主题/改设置触感反馈（sensoryFeedback，iOS17+ 守卫）；休息日不再冷清 ¥0，改显本月累计 + 温暖文案
- **全天计薪模式**：SalaryConfig 加 `earningMode`（工作时段/全天24h），引擎按模式分支——全天 = 月薪÷当月天数÷86400，天天每秒都涨、无休息日；设置页加模式切换，全天模式隐藏工时/工作日设置
- 设置页加模式说明 footer：解释两模式数字不同但月底总额一致（避免用户困惑）
- Codable 向后兼容（旧存档无 earningMode 默认工作时段）
- 40 单测通过（新增 8 个全天模式 + 此前体验改动）

### V3.0：上架赚钱方向转向（进行中）
定位确认：本产品是**情绪消费品（摸鱼爽感）**，非 HR 工具。收益只来自「免费走量 → 分享传播 → 留存」，故砍掉加班/税费/iCloud 等「工具完整度」功能，优先做获客与留存。
- **分享战绩卡**（获客 + 过审核心）：`ShareCardView`（4:5 竖版主题渐变卡，金额主角 + 摸鱼梗 + App 水印）+ `ShareCardRenderer`（ImageRenderer 渲染成 PNG）+ `ShareCardSheet`（预览 + ShareLink）。收入页右上角「晒一晒」入口。冻结金额快照保证预览与分享图一致。
- **上瘾钩子**（留存）：hero 卡工作中显示下班倒计时（盯着摸鱼的回访动机）+ 实物换算「≈ N 顿火锅」（`MoneyEquivalent` 纯函数，选「数量1...99 的最贵实物」，极大额用最贵兜底）。
- **修技术雷**：① 节假日跨年——`HolidayData.supportedYears`/`hasData`，缺当年数据时主页橙色横幅提示「按星期几估算可能有偏差」，不再 2027 起静默算错；② Widget 刷新防抖——`reloadAllTimelines` 改 0.6s DispatchWorkItem 防抖，拖 DatePicker 不烧刷新预算。
- 50 单测通过（新增分享卡渲染 2 + 实物换算 5 + 节假日覆盖 3）。
- **下一步等账号**：上架材料（隐私政策、截图、ASO 关键词「摸鱼/时薪/上班赚钱」）。需个人开发者账号 ¥688/年。注意 Guideline 4.2「最低功能」过审风险——分享/钩子同时是过审筹码。

## 编译路径（App target）

```
App/SalaryCountApp.swift        # @main + 引导页路由
App/OnboardingView.swift        # 首次启动引导
Sources/Models/SalaryConfig.swift
Sources/Models/HolidayConfig.swift
Sources/Engine/SalaryEngine.swift
Sources/Store/SalaryStore.swift
Sources/Store/AppGroup.swift
Sources/Views/HomeView.swift
Sources/Views/SettingsView.swift
Sources/Views/ShareCardView.swift      # 分享战绩卡（脱离环境独立渲染）
Sources/Views/ShareCardRenderer.swift  # ImageRenderer → PNG/UIImage
Sources/Views/ShareCardSheet.swift     # 卡片预览 + ShareLink
```
Widget target 另含 Widget/ 下文件 + 共享的 Engine/Models/AppGroup。

## 已知限制

- 节假日数据仅内置 2026；缺当年数据时退化为按星期几（已有主页提示，非静默）
- 无加班、税费计算（已主动砍出范围：情绪消费品不靠功能完整度）
- 不支持跨午夜班次（安全归零）
- Widget 受系统刷新节流，非逐秒（设计上以真实快照 + 进度推进诚实表达）

## 下一步

定位为情绪消费品，优先级 = 获客 > 留存 > 工具完整度：
1. **上架材料**（等开发者账号）：隐私政策、截图、ASO 关键词。Guideline 4.2 过审风险——分享/钩子是筹码。
2. 留存增强：连续打卡、Widget 也加倒计时/换算。
3. 分享传播增强：年度摸鱼报告、更多梗文案。
4. （远期、低优先）节假日逐年扩充、加班/税费。

## 真机部署提示

App Group `group.com.jasper.salarycount` 需在 Apple 开发者账号开启该能力，并将 App 与 Widget 两个 target 改为团队自动签名。模拟器无需此步。
