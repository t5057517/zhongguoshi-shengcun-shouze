# 中国式生存守则

黑色幽默情景游戏。以中国日常人情、客套与隐性规则为题材，用一次移动、转向或简单摆放，应对那些没人明说却人人都懂的规矩。

- **H5 版**：竖屏 375×600，跑在微信内置浏览器/手机浏览器。
- **PC 版**：Electron 桌面客户端，横屏窗口 + 关卡侧栏，可打包成 `.exe`。

## 玩法

看懂场面 → 简单操作 → 现场反应 → 下一关。每关只使用一种主要操作。

## 关卡（当前 4 关，规划 99 关）

1. 只剪一次 — 拖动手机扫码付款
2. 我只是想关掉它 — 关闭开屏广告并卸载 App
3. 验证码 — 从横幅广告中找出验证码
4. 回T退订 — 发短信退订

## 目录结构

```
├── H5/            # H5 版（移动端竖屏）
│   ├── index.html
│   ├── main.js    # 引擎
│   └── level1~4.js # 关卡
├── PC/            # PC 版（Electron 桌面客户端，横屏）
│   ├── package.json
│   ├── main.js    # Electron 主进程
│   ├── preload.js
│   └── renderer/
│       ├── index.html  # 桌面布局：侧栏 + 手机画布
│       ├── engine.js   # PC 引擎
│       └── levels/     # 关卡（与 H5 同逻辑）
└── 案子/          # 企划书与关卡策划案（.docx）
```

## 运行

### H5 版

```bash
cd H5 && python -m http.server 8123
# 浏览器访问 http://localhost:8123
```

### PC 版（Electron）

```bash
cd PC
npm install
npm start          # 开发运行
npm run dist       # 打包 Windows 安装包（nsis + 便携版）
```

打包产物在 `PC/dist/`。

## 开发说明

- 两端共用同一套关卡逻辑（375×600 画布坐标系），PC 端把该画布等比缩放放进桌面窗口，并额外提供关卡侧栏。
- 新增关卡：在 `H5/levelN.js` 用 `window.registerLevel(id, { title, results, create(core, finish) })` 注册，再复制到 `PC/renderer/levels/`，并在 `index.html` 引入。
- 二进制文档（`.docx`）Git 无法 diff，改策划案前先 `git pull`，改完立刻提交，避免冲突。
