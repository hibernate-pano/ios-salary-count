# 工资计算器 (SalaryCount)

一个 iOS App，实时显示你的工作收入——打开就能看到今天赚的钱一秒一秒往上涨。

## 当前状态：V1 可运行骨架 ✅

干净重写的最小可用版本，已在 iPhone 模拟器上验证通过：

- 实时跳动的「今日已赚」（每秒刷新）
- 本月累计、年度累计收入
- 设置：月薪、上下班时间、午休开关、工作日选择
- 配置本地持久化，深浅色自动跟随系统
- 16 个引擎单元测试全部通过

## 技术栈

- SwiftUI，iOS 16.0+
- 工程用 [XcodeGen](https://github.com/yonomi/xcodegen) 从 `project.yml` 生成（可重建、可进 git）
- 配置持久化：Codable + UserDefaults
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

V1 已落地的是地基。后续按优先级逐步叠加，每步都保持可运行、可测试：

- [ ] 桌面小组件（受系统刷新节流，显示慢更新快照而非逐秒）
- [ ] 中国法定节假日 / 调休（内置数据，不依赖第三方 API）
- [ ] 加班工资、特殊节假日工资
- [ ] iCloud 同步
- [ ] 多语言、用户引导
- [ ] App Store 上架材料（截图、描述、隐私政策）

## 许可证

MIT License
