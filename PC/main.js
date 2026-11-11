// 《中国式生存守则》PC 客户端 — Electron 主进程
const { app, BrowserWindow, Menu } = require('electron');
const path = require('path');

// 横屏桌面窗口：核心交互区 800x600（PC 用横屏布局）
const DESIGN_W = 800;
const DESIGN_H = 600;

let win;

function createWindow() {
  win = new BrowserWindow({
    width: DESIGN_W,
    height: DESIGN_H,
    minWidth: 640,
    minHeight: 480,
    useContentSize: true,
    resizable: true,
    autoHideMenuBar: true,
    backgroundColor: '#e9e2d6',
    title: '中国式生存守则',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  // 去掉默认菜单栏
  Menu.setApplicationMenu(null);

  win.loadFile(path.join(__dirname, 'renderer', 'index.html'));
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
