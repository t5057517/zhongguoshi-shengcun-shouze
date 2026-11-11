// 预加载脚本：预留安全的 IPC 通道
const { contextBridge } = require('electron');

contextBridge.exposeInMainWorld('desktop', {
  isElectron: true,
  platform: process.platform
});
