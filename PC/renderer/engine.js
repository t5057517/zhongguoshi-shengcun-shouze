/* 中国式生存守则 —— PC 版引擎
 * 复用 H5 关卡逻辑（375×600 画布），套进桌面窗口 + 关卡侧栏
 */
(function () {
  'use strict';

  const DESIGN_W = 375;
  const DESIGN_H = 600;

  const stage = document.getElementById('stage');
  const core = document.getElementById('core');
  const fadeEl = document.getElementById('fade');
  const fadeTt = fadeEl.querySelector('.tt');
  const phoneFrame = document.getElementById('phone-frame');
  const main = document.getElementById('main');

  // 手机画布在桌面窗口内等比缩放
  function resize() {
    const mw = main.clientWidth;
    const mh = main.clientHeight;
    // 留出边距
    const availW = mw - 80;
    const availH = mh - 80;
    const s = Math.min(availW / DESIGN_W, availH / DESIGN_H, 1.15);
    phoneFrame.style.transform = 'scale(' + s + ')';
  }
  window.addEventListener('resize', resize);

  // 右键菜单屏蔽
  document.addEventListener('contextmenu', function (e) { e.preventDefault(); });

  // 音频解锁
  let audioUnlocked = false;
  function unlockAudio() {
    if (audioUnlocked) return;
    audioUnlocked = true;
    try {
      const AC = window.AudioContext || window.webkitAudioContext;
      window.__ac = new AC();
      window.__ac.resume();
    } catch (e) {}
  }
  document.addEventListener('pointerdown', unlockAudio);

  // 音效
  let ac = null;
  function beep(freq, dur, type) {
    if (!window.__ac) return;
    ac = ac || window.__ac;
    try {
      const o = ac.createOscillator();
      const g = ac.createGain();
      o.type = type || 'sine';
      o.frequency.value = freq;
      g.gain.value = 0.12;
      o.connect(g); g.connect(ac.destination);
      o.start();
      g.gain.exponentialRampToValueAtTime(0.0001, ac.currentTime + dur);
      o.stop(ac.currentTime + dur);
    } catch (e) {}
  }

  // 关卡注册
  const levels = [];
  const registry = {};
  function registerLevel(id, opts) {
    registry[id] = opts;
    levels.push(id);
  }
  window.registerLevel = registerLevel;

  const results = [];

  function finishLevel(resultId) {
    results.push(resultId);
    beep(660, 0.12);
    showTitle(resultId);
  }

  function showTitle(resultId) {
    const lv = registry[currentLevel];
    const info = lv ? lv.results[resultId] : null;
    fadeEl.classList.remove('show');
    fadeEl.style.opacity = '0';
    let txt = '';
    if (info && info.title) txt = info.title;
    else if (lv) txt = lv.title;
    fadeTt.textContent = txt;
    setTimeout(function () {
      fadeEl.classList.add('show');
      fadeEl.style.opacity = '1';
    }, 500);
  }

  function nextLevel() {
    if (fadeEl.classList.contains('show')) {
      fadeEl.classList.remove('show');
      fadeEl.style.opacity = '0';
    }
    advance(currentIndex + 1);
  }
  fadeEl.addEventListener('pointerdown', nextLevel);

  let currentIndex = -1;
  let currentLevel = null;

  // 侧栏关卡列表
  const levelListEl = document.getElementById('level-list');
  function buildSidebar() {
    levelListEl.innerHTML = '';
    levels.forEach(function (id, i) {
      const lv = registry[id];
      const item = document.createElement('div');
      item.className = 'lv-item';
      item.dataset.index = i;
      item.innerHTML = '<span class="num">' + (i + 1) + '</span><span>' + (lv.title || id) + '</span>';
      item.addEventListener('click', function () {
        advance(i);
      });
      levelListEl.appendChild(item);
    });
  }
  function syncSidebar() {
    const items = levelListEl.children;
    for (let i = 0; i < items.length; i++) {
      items[i].classList.toggle('active', i === currentIndex);
    }
  }

  function advance(idx) {
    currentIndex = idx;
    if (currentIndex >= levels.length) currentIndex = 0;
    if (currentIndex < 0) currentIndex = 0;
    currentLevel = levels[currentIndex];

    core.innerHTML = '';
    const lv = registry[currentLevel];
    if (lv && lv.create) {
      lv.create(core, finishLevel);
    }
    const hud = document.createElement('div');
    hud.className = 'hud';
    hud.innerHTML = '<span class="lv">第 ' + (currentIndex + 1) + ' 关</span><span>' + (lv.title || '') + '</span>';
    core.appendChild(hud);
    syncSidebar();
  }

  function start() {
    buildSidebar();
    resize();
    advance(0);
  }

  window.__game = {
    core, stage, finishLevel, beep,
    DESIGN_W, DESIGN_H, results,
    advance, start
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
