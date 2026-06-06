# 上架检查清单 & 发布配置说明

> 账号到位后，照这份从上到下走。分两部分：**A. 发布前要改的工程配置**（我已写好现成内容，你照贴）、**B. App Store Connect 上架步骤**。

---

## 现状基线

- App 名：牛马薪水计算器
- Bundle ID：`com.jasper.salarycount`（⚠️ 上架前可改，一旦提交不可再变，见下）
- 版本：0.8
- 最低系统：iOS 16.0
- 免费账号已能装真机，但**小组件（Widget）和 App Group 被暂时移除**了——付费账号后恢复

---

## A. 发布前的工程配置改动

### A1. 确认 / 修改 Bundle ID

`com.jasper.salarycount` 里的 `jasper` 是占位。上架前若要换成你自己的标识（如 `com.<你的名字或公司>.salarycount`）：
- 改 `project.yml` 里所有 `PRODUCT_BUNDLE_IDENTIFIER`
- 改两个 entitlements 和 `AppGroup.swift` 里的 App Group ID（保持三处一致）
- **决定好就别再改**——提交到 App Store Connect 后 Bundle ID 锁定

### A2. 恢复 Widget + App Group（付费账号才支持）

当前 `project.yml` 的 App target 没有 Widget 依赖、没有 App Group entitlement。付费账号配好后，把 `project.yml` 的 targets 段恢复成下面这样（**含 Widget target + App target 的 entitlements + 依赖**）：

```yaml
targets:
  SalaryCount:
    type: application
    platform: iOS
    sources:
      - path: App
      - path: Sources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.jasper.salarycount
        PRODUCT_NAME: SalaryCount
        INFOPLIST_FILE: App/Info.plist
        CODE_SIGN_ENTITLEMENTS: App/SalaryCount.entitlements   # ← 恢复这行
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        TARGETED_DEVICE_FAMILY: "1"
    dependencies:
      - target: SalaryWidgetExtension                           # ← 恢复这块

  SalaryWidgetExtension:                                        # ← 恢复整个 target
    type: app-extension
    platform: iOS
    sources:
      - path: Widget
      - path: Sources/Engine
      - path: Sources/Models
      - path: Sources/Store/AppGroup.swift
      - path: Sources/DesignSystem
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.jasper.salarycount.widget
        PRODUCT_NAME: SalaryWidgetExtension
        INFOPLIST_FILE: Widget/Info.plist
        CODE_SIGN_ENTITLEMENTS: Widget/SalaryWidget.entitlements
        TARGETED_DEVICE_FAMILY: "1"

  # SalaryCountTests / SalaryCountUITests 保持不变
```

> 这一步交给我做就行——你账号好了告诉我，我来改 + 验证编译。Widget/entitlements 文件都还在仓库里。

### A3. App Group 在开发者后台启用

付费账号后，在 [Apple Developer → Certificates, IDs & Profiles → Identifiers]：
1. 给 App ID `com.jasper.salarycount` 和 Widget ID `com.jasper.salarycount.widget` 都勾选 **App Groups** 能力
2. 创建 App Group `group.com.jasper.salarycount`，把两个 ID 都加进去
3. Xcode 里用自动签名会自动拉取 profile（我会在改配置时一起验证）

### A4. 把签名改成正式发布签名

- 免费账号现在是 `CODE_SIGN_STYLE: Automatic` + 你的 Personal Team
- 付费账号后 Team 换成你的付费团队 ID（Xcode 登录后自动出现），仍用自动签名
- 归档发布时 Xcode 自动生成 Distribution profile

### A5. （可选增强）iCloud 跨设备同步

**现状**：配置存本地 App Group UserDefaults。更新版本不丢、整机迁移能带过去；唯一缺口是「新手机全新下载 App、没走整机备份」时配置不同步，需重填。

**方案**：用 `NSUbiquitousKeyValueStore`（iCloud 键值同步），配置极小正好匹配，轻量免费。

**前提**：需付费账号开启 iCloud (Key-Value storage) 能力。账号到位后告诉我，我来实现 + 模拟器验证。

> 优先级：低。多数用户走整机迁移，数据本就能带过去。属于「换机零感知」的体验增强，非阻塞上架。

---

## B. App Store Connect 上架步骤

### B1. 准备账号与 App 记录
1. [developer.apple.com](https://developer.apple.com) 注册付费开发者计划（$99/年），等审核通过（个人通常 1–2 天）
2. [App Store Connect](https://appstoreconnect.apple.com) → My Apps → ➕ → New App
   - 平台 iOS，名称「牛马薪水计算器」，主语言 简体中文
   - Bundle ID 选 `com.jasper.salarycount`，SKU 随便填个唯一串（如 `salarycount2026`）

### B2. 填元数据（资料都在 store/ 目录）
- **描述 / 副标题 / 关键词 / 促销文本** → 见 `AppStoreListing.md`
- **分类**：财务（主）/ 效率（次）
- **年龄分级**：填问卷，全选「无」→ 4+
- **隐私政策 URL** → 见 B5
- **App 隐私（营养标签）** → 见 `PrivacyNutritionLabel.md`（全选「不收集」）
- **截图** → 见 `screenshots/` 目录（需 6.7" 和 6.5" 两种尺寸，App Store 必需）

### B3. 上传构建
1. 我帮你把 project.yml 改好（A2）后，Xcode 里 Product → Archive
2. Organizer → Distribute App → App Store Connect → Upload
3. 等几分钟构建出现在 App Store Connect 的 TestFlight/构建列表里
4. 在版本页面选中该构建

### B4. 提交审核
- 填「审核备注」：可写"本 App 完全离线运行，无需登录，无需测试账号。"
- 提交。首次审核通常 1–3 天

### B5. 隐私政策 URL（必填项）
App Store 要求一个公开可访问的隐私政策网址。`store/PrivacyPolicy.md` 内容已备好，三种托管方式任选：
1. **GitHub Pages**（免费，推荐）：把 PrivacyPolicy 放到一个公开仓库开 Pages，得到 `https://<用户名>.github.io/...` 链接
2. **GitHub 仓库直接看**：把 .md 推到公开仓库，用文件的 raw/blob 链接（最省事）
3. 任何你有的网站/博客贴一页

> 这步要你来做（需要你的 GitHub/网站账号）。链接生成后填进 App Store Connect 的 Privacy Policy URL。

---

## 需要你做 vs 我做

**只有你能做的：**
- 注册付费开发者账号、付款
- App Store Connect 建 App、填元数据、上传构建、提交审核（这些要你的账号登录）
- 托管隐私政策拿到 URL
- 最终决定 Bundle ID

**我帮你做的：**
- 改 project.yml 恢复 Widget + 正式签名配置，验证编译归档
- 所有文案、隐私政策、截图素材（已在 store/ 目录）
- 配 App Group、排查签名报错

---

## 资料清单（store/ 目录）

- `PrivacyPolicy.md` —— 隐私政策（中英文，待你托管成 URL）
- `AppStoreListing.md` —— 应用名/副标题/描述/关键词/更新说明
- `PrivacyNutritionLabel.md` —— App 隐私问卷怎么填
- `LaunchChecklist.md` —— 本文件
- `screenshots/` —— App Store 截图素材
