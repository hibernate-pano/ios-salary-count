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
```
Widget target 另含 Widget/ 下文件 + 共享的 Engine/Models/AppGroup。

## 已知限制

- 节假日按「星期几」判断，接口已留但未接入法定节假日/调休数据
- 无加班、税费计算
- 不支持跨午夜班次（安全归零）
- Widget 受系统刷新节流，非逐秒（设计上以真实快照 + 进度推进诚实表达）

## 下一步（V3 候选）

按优先级：接入法定节假日数据（接口已就绪）→ 加班/税费 → 统计图表 → iCloud 同步 → App Store 上架材料。

## 真机部署提示

App Group `group.com.jasper.salarycount` 需在 Apple 开发者账号开启该能力，并将 App 与 Widget 两个 target 改为团队自动签名。模拟器无需此步。
