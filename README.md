# 工资计算器 (SalaryCount)

一个 iOS App，实时显示你的工作收入——打开就能看到今天赚的钱一秒一秒往上涨。

## 当前状态：V2 App + 桌面小组件 ✅

干净重写的可用版本，已在 iPhone 模拟器上验证通过：

**App**
- 实时跳动的「今日已赚」（每秒刷新）
- 本月累计、年度累计收入
- 设置：月薪、上下班时间、午休开关、工作日选择
- 配置持久化，深浅色自动跟随系统

**桌面小组件（Widget）**
- 小/中/大三种尺寸，进度环 + 金额母题
- 工作进度可视化（诚实表达「钱在涨」，不伪造逐秒跳动）
- 五种状态自适应：未开工/工作中/午休/已下班/休息日
- 通过 App Group 与 App 共享配置，改设置即时刷新

**质量**
- 23 个引擎单元测试全部通过
- Widget 实现经多维度评审 + 对抗性验证，修复 7 项确认问题

## 技术栈

- SwiftUI + WidgetKit，iOS 16.0+
- 工程用 [XcodeGen](https://github.com/yonomi/xcodegen) 从 `project.yml` 生成（可重建、可进 git）
- 配置持久化：Codable + App Group UserDefaults（App 与 Widget 共享）
- 时间以「自午夜分钟数」存储，脱离时区/夏令时
- 计算引擎为纯函数，便于测试

## 项目结构

```
ios-salary-count/
├── project.yml                  # XcodeGen 工程配置
├── App/
│   ├── SalaryCountApp.swift      # @main 入口 + TabView
│   ├── Info.plist
│   └── Assets.xcassets/          # AppIcon + AccentColor
├── Sources/
│   ├── Models/SalaryConfig.swift # 配置（值类型）
│   ├── Engine/SalaryEngine.swift # 计算引擎（纯函数）
│   ├── Store/SalaryStore.swift   # 状态管理 + 1秒 Timer + 持久化
│   └── Views/
│       ├── HomeView.swift        # 实时收入主页
│       └── SettingsView.swift    # 设置
└── Tests/SalaryEngineTests.swift
```

## 计算逻辑

```
日工资   = 月薪 ÷ 当月工作日数
每秒工资 = 日工资 ÷ 每日有效工作秒数（已扣午休）
今日收入 = 已工作秒数 × 每秒工资
本月收入 = 本月已完成工作日 × 日工资 + 今日收入
年度收入 = 已过完整月份 × 月薪 + 本月收入
```

> weekday 约定与 Apple Calendar 一致：1=周日 … 7=周六，默认工作日为周一到周五 `[2,3,4,5,6]`。

## 如何运行

```bash
# 1. 安装 XcodeGen（首次）
brew install xcodegen

# 2. 生成 Xcode 工程
xcodegen generate

# 3. 用 Xcode 打开，选模拟器运行
open SalaryCount.xcodeproj

# 或命令行编译 + 测试
xcodebuild -project SalaryCount.xcodeproj -scheme SalaryCount \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## 路线图

每步都保持可运行、可测试：

- [x] V1 可运行骨架（App 核心 + 实时跳动）
- [x] 桌面小组件（进度环 + App Group 共享，慢更新真实快照）
- [ ] 中国法定节假日 / 调休（内置数据，不依赖第三方 API）
- [ ] 加班工资、特殊节假日工资
- [ ] 跨午夜班次支持（夜班，需重构「日」的语义）
- [ ] iCloud 同步
- [ ] 多语言、用户引导
- [ ] App Store 上架材料（截图、描述、隐私政策）

> 真机部署提示：App Group（`group.com.jasper.salarycount`）需在 Apple 开发者账号开启该能力，并将两个 target 改为你的团队自动签名。模拟器无需此步。

## 许可证

MIT License
