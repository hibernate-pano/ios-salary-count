# iOS 工资计算小组件 (iOS Salary Widget)

一个简单而实用的 iOS 桌面小组件，帮助用户实时追踪他们的工作收入。

## 功能特点

### 核心功能
- 实时计算每秒工资收入
- 支持自定义月薪和工作时间设置
- 智能识别工作日和工作时间
- 多维度收入统计展示
- 自动同步国家法定节假日

### 数据展示
- 今日收入统计
- 本月累计收入
- 年度累计收入
- 实时每秒收入

### 个性化设置
- 自定义月薪金额
- 设置工作时间（默认 9:00-18:00）
- 设置午休时间（可选）
- 选择工作日（默认周一至周五）

### 小组件设计
- 支持小、中、大三种尺寸
  - 小尺寸：显示今日实时收入
  - 中尺寸：显示今日和本月累计收入
  - 大尺寸：显示今日、本月和年度累计收入
- 支持深色/浅色模式自动切换
- 简洁现代的界面设计

## 技术实现

### 开发环境
- iOS 16.0+
- SwiftUI
- WidgetKit
- SwiftData (用于数据持久化)

### 核心算法
1. 日工资计算
   ```
   日工资 = 月薪 ÷ 当月工作日数
   ```

2. 每秒工资计算
   ```
   每秒工资 = 日工资 ÷ (每日工作秒数 - 午休秒数)
   ```

3. 实时收入计算
   ```
   当前收入 = 每秒工资 × 已工作秒数
   ```

### 数据存储
- 使用 SwiftData 存储用户配置
- 本地缓存节假日信息
- 自动同步国家法定节假日数据

## 项目结构
```
ios-salary-count/
├── Sources/
│   └── ios-salary-count/
│       ├── Widget/
│       │   ├── SalaryWidget.swift
│       │   ├── SalaryWidgetBundle.swift
│       │   └── WidgetViews/
│       │       ├── SmallWidgetView.swift
│       │       ├── MediumWidgetView.swift
│       │       └── LargeWidgetView.swift
│       ├── Models/
│       │   ├── SalaryConfig.swift
│       │   ├── WorkTimeConfig.swift
│       │   └── HolidayConfig.swift
│       ├── Views/
│       │   ├── ConfigView.swift
│       │   └── WidgetView.swift
│       ├── Utils/
│       │   ├── SalaryCalculator.swift
│       │   ├── WorkDayHelper.swift
│       │   └── HolidayHelper.swift
│       ├── SalaryApp.swift
│       └── Info.plist
├── Tests/
├── Package.swift
└── README.md
```

## 系统要求

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## 安装说明

1. 克隆项目到本地
2. 使用 Xcode 打开项目
3. 选择目标设备或模拟器
4. 点击运行按钮

## 使用说明

1. 在设置页面配置你的月薪和工作时间
2. 在主屏幕添加小组件
3. 选择合适的小组件尺寸
4. 实时查看你的工作收入

## 开发计划

### 第一阶段：基础功能实现
- [x] 项目初始化
- [x] 基础 UI 框架搭建
- [x] 工资计算核心逻辑实现
- [x] 小组件开发
- [x] 数据持久化

### 第二阶段：功能完善
- [ ] 节假日同步功能
- [ ] 深色/浅色模式支持
- [ ] 多语言支持
- [ ] 数据备份/恢复
- [ ] 用户引导流程

### 第三阶段：性能优化
- [ ] 缓存机制优化
- [ ] 后台任务优化
- [ ] 内存管理优化
- [ ] 网络请求优化
- [ ] 小组件刷新优化

### 第四阶段：质量保证
- [ ] 单元测试编写
- [ ] UI 测试编写
- [ ] 性能测试
- [ ] 内存泄漏检测
- [ ] 崩溃监控

### 第五阶段：发布准备
- [ ] App Store 发布材料准备
- [ ] 应用截图制作
- [ ] 应用描述编写
- [ ] 关键词优化
- [ ] 隐私政策更新

## 贡献指南

1. Fork 本仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的改动 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 许可证

MIT License 