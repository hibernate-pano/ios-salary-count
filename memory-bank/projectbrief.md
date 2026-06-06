# 项目简介：工资计算器 (SalaryCount)

## 是什么

一个 iOS「实时工资计数器」。上班时间里，用户看着自己赚的每一秒钱在屏幕上实时跳动，并能通过桌面小组件随时一眼看到。

核心体验：填月薪 + 上下班时间 → 主页看今日/本月/年度收入实时累计 + 桌面小组件展示进度。

## 真实定位（重要）

本项目源自一份「虚构的全功能产品文档」（曾把它描述成含社保/公积金/个税/iCloud 同步/多方案对比的 HR 薪资工具），但代码从未实现这些，且原代码无法编译。已对齐到真实产品——「实时工资计数器」。

## 范围

**已完成（V2）**
- 实时工资主界面（今日/本月/年度，每秒跳动）
- 设置页（月薪、上下班、午休、工作日）
- 首次启动引导页（3 页）
- 桌面小组件（小/中/大三尺寸，进度环 + 金额，App Group 共享）
- 本地持久化（Codable + App Group UserDefaults）

**明确不做（当前）**
- 联网法定节假日/调休（接口已留，数据源未接）
- 加班倍率、社保税费
- 统计图表、数据导入导出、iCloud 同步
- 跨午夜班次（夜班）——与按日历日统计的模型不兼容，安全归零

## 技术决策

- SwiftUI + WidgetKit，iOS 16.0+
- **持久化用 Codable + App Group UserDefaults**，不用 SwiftData（V1 只存单一配置对象，且需与 Widget 共享，UserDefaults 更轻更稳，iOS16 可用）
- 时间以「自午夜分钟数」(Int) 存储，脱离时区/夏令时
- 计算引擎 `SalaryEngine` 纯函数、可测试，与界面解耦
- App 内实时刷新用 `Timer`（1 秒）；Widget 受系统节流，用 TimelineProvider 预生成真实快照
- 工程用 XcodeGen 从 `project.yml` 生成，可重建、可进 git
- 节假日接口已预留：`SalaryEngine.isWorkday` 接受 `holidays`，判定优先级 调休补班 > 法定节假日 > 按星期几

## 与孪生项目的关系

存在一个同源项目 `salary-calculator`（SwiftData + TimelineView 技术栈），二者独立演化到相同定位。本项目功能领先（已有 Widget/App Group），已汲取其引导页、节假日接口、UI 测试、memory-bank 文档等理念（按本项目架构重新实现，未引入 SwiftData）。
