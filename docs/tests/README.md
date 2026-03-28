# 前端测试文档索引

本目录包含股票筛选器前端功能的所有测试相关文档。

---

## 文档列表

### 1. [测试用例文档](./frontend-test-cases.md)

**文件**: `frontend-test-cases.md`

**用途**: 详细的测试用例集合，包含测试步骤、预期结果

**内容**:
- 85+ 个测试用例
- 覆盖 6 大功能模块
- 包含 P0-P3 优先级标记

**适用场景**:
- 测试人员执行详细测试
- 回归测试参考
- 测试覆盖率检查

---

### 2. [测试检查清单](./frontend-checklist.md)

**文件**: `frontend-checklist.md`

**用途**: 快速检查清单，用于手动测试

**内容**:
- 85 项检查清单
- 可打印的表格格式
- 包含测试总结模板

**适用场景**:
- 快速手动测试
- 发布前检查
- 测试记录存档

---

### 3. [UI/UX 问题报告](./frontend-ux-issues.md)

**文件**: `frontend-ux-issues.md`

**用途**: 记录和跟踪 UI/UX 问题

**内容**:
- 已发现的问题（优先级、描述、复现步骤）
- 改进建议
- 修复记录

**适用场景**:
- UI 问题跟踪
- 产品优化参考
- 版本迭代规划

---

## 测试范围

### 功能模块

| 模块 | 测试用例数 | 检查项数 |
|------|-----------|---------|
| 指标说明提示 | 5 | 10 |
| 指标筛选操作 | 15 | 17 |
| 权重排序功能 | 10 | 13 |
| 启用/禁用切换 | 5 | 7 |
| 指标选择与移除 | 4 | 9 |
| 响应式布局 | 5 | 8 |
| UI/UX 体验 | 12 | 12 |
| 浏览器兼容性 | 4 | 4 |
| 性能测试 | 5 | 5 |
| **总计** | **65+** | **85** |

### 测试类型

- ✅ 功能测试
- ✅ UI/UX 测试
- ✅ 兼容性测试
- ✅ 性能测试
- ✅ 探索性测试

---

## 快速开始

### 执行完整测试

1. 打开 [测试检查清单](./frontend-checklist.md)
2. 逐项执行检查
3. 在对应状态栏标记 ✓ 或 ✗
4. 发现问题记录到 [UI/UX 问题报告](./frontend-ux-issues.md)

### 验证特定功能

1. 打开 [测试用例文档](./frontend-test-cases.md)
2. 找到对应模块（如 TC-FILTER 为筛选操作）
3. 按步骤执行测试

### 查看已知问题

直接查看 [UI/UX 问题报告](./frontend-ux-issues.md) 的"已发现问题"章节

---

## 被测文件

| 文件 | 路径 | 说明 |
|------|------|------|
| screener.html | `www/screener.html` | 主页面 |
| screener.js | `www/screener.js` | 主逻辑 |
| indicator-card.js | `www/components/indicator-card.js` | 指标卡片组件 |
| filter-controls.js | `www/components/filter-controls.js` | 筛选控件组件 |
| screener.css | `www/screener.css` | 页面样式 |
| indicator-card.css | `www/components/indicator-card.css` | 卡片样式 |
| filter-controls.css | `www/components/filter-controls.css` | 筛选控件样式 |

---

## 测试环境要求

### 浏览器

- Chrome 最新版 (P0)
- Firefox 最新版 (P1)
- Safari 最新版 (P1)
- Edge 最新版 (P1)

### 分辨率

- 1920x1080 (桌面)
- 1366x768 (笔记本)
- 768x1024 (平板)
- 375x667 (手机)

---

## 相关文档

- [核心模块 API 参考](../api-reference.md) - 指标计算公式
- [架构设计](../architecture.md) - 前端架构说明
- [用户指南](../user-guide.md) - 功能使用说明

---

## 更新记录

| 日期 | 版本 | 更新内容 | 更新人 |
|------|------|---------|--------|
| 2026-03-28 | v1.0.0 | 初始版本，创建测试用例、检查清单、问题报告 | frontend-dev |

---

## 联系方式

发现问题或需要更新文档，请联系前端测试负责人。

---

**文档维护**: frontend-dev
**最后更新**: 2026-03-28
