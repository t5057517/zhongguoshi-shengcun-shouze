/* 中国式生存守则 —— H5 原型
 * 竖屏 375×600 核心交互区，缩放适配，单页内切换关卡
 */
(function () {
  'use strict';

  const DESIGN_W = 375;
  const DESIGN_H = 600;

  const stage = document.getElementById('stage');
  const core = document.getElementById('core');
  const fadeEl = document.getElementById('fade');
  const fadeTt = fadeEl.querySelector('.tt');
  const landscapeEl = document.getElementById('landscape');

  let scale = 1;
  function resize() {
    const w = window.innerWidth;
    const h = window.innerHeight;

    // 等比缩放：既保证核心区 375 宽完整显示，也保证 600 高完整显示
    scale = Math.min(w / DESIGN_W, h / DESIGN_H);

    const stageW = DESIGN_W * scale;
    const stageH = DESIGN_H * scale;

    stage.style.width = stageW + 'px';
    stage.style.height = stageH + 'px';
    // 水平 + 垂直都居中
    stage.style.left = Math.floor((w - stageW) / 2) + 'px';
    stage.style.top = Math.floor((h - stageH) / 2) + 'px';
    stage.style.transform = 'scale(' + scale + ')';
    stage.style.transformOrigin = 'top left';

    // 核心区填满 stage（不再有偏移）
    core.style.top = '0px';
  }
  window.addEventListener('resize', resize);

  // 桌面浏览器（精细指针，鼠标）强制关闭横屏遮罩，避免误拦
  function isCoarsePointer() {
    return window.matchMedia && window.matchMedia('(pointer:coarse)').matches;
  }
  function updateLandscape() {
    if (!landscapeEl) return;
    if (!isCoarsePointer()) {
      landscapeEl.style.display = 'none';
    } else {
      landscapeEl.style.display = '';
    }
  }
  updateLandscape();
  window.addEventListener('resize', updateLandscape);

  // 禁止滚动回弹 + 长按菜单
  document.addEventListener('touchmove', function (e) {
    e.preventDefault();
  }, { passive: false });
  document.addEventListener('contextmenu', function (e) { e.preventDefault(); });
  document.addEventListener('gesturestart', function (e) { e.preventDefault(); });

  // 音频解锁（首次点击）
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
  document.addEventListener('touchstart', unlockAudio);

  // 简单音效
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
  window.__beep = beep;

  // ---- 关卡注册 ----
  const levels = [];
  const registry = {};
  function registerLevel(id, opts) {
    registry[id] = opts;
    levels.push(id);
  }
  window.registerLevel = registerLevel;

  const results = []; // result_id 记录

  // 结果演出 -> 黑屏 0.5s -> 标题 -> 点击继续
  function finishLevel(resultId) {
    results.push(resultId);
    beep(660, 0.12);
    // 结果演出：各关卡在自己的 finish 前已做演出，此处只做转场
    showTitle(resultId);
  }

  function showTitle(resultId) {
    const lv = registry[currentLevel];
    const info = lv ? lv.results[resultId] : null;
    // 黑屏 0.5 秒后显示标题
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
      fadeEl.removeEventListener('pointerdown', nextLevel);
    }
    advance();
  }

  fadeEl.addEventListener('pointerdown', nextLevel);

  let currentIndex = -1;
  let currentLevel = null;
  let levelInstance = null;

  function advance() {
    currentIndex++;
    if (currentIndex >= levels.length) {
      currentIndex = 0; // 循环演示
    }
    currentLevel = levels[currentIndex];
    core.innerHTML = '';
    const lv = registry[currentLevel];
    if (lv && lv.create) {
      levelInstance = lv.create(core, finishLevel);
    }
    // 顶部 HUD
    const hud = document.createElement('div');
    hud.className = 'hud';
    hud.innerHTML = '<span class="lv">第 ' + (currentIndex + 1) + ' 关</span><span>' + (lv.title || '') + '</span>';
    core.appendChild(hud);
  }

  function start() {
    resize();
    advance();
  }

  window.__game = {
    core, stage, finishLevel, beep,
    DESIGN_W, DESIGN_H, results,
    start
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
