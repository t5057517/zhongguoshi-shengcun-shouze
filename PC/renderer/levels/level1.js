/* 第一关：只剪一次（理发店收银台） */
(function () {
  const G = window.__game;
  const DESIGN_W = G.DESIGN_W;

  window.registerLevel('haircut', {
    title: '只剪一次',
    results: {
      single: { title: '支付成功 ¥38' },
      card: { title: '至尊黑金卡 ¥6888' }
    },
    create(core, finish) {
      const root = document.createElement('div');
      root.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;overflow:hidden;background:linear-gradient(#e8dccb,#d9cbb4);';
      core.appendChild(root);

      // 收银台
      const desk = document.createElement('div');
      desk.style.cssText = 'position:absolute;left:20px;top:40px;width:335px;height:250px;background:#a9805a;border-radius:10px;box-shadow:inset 0 -6px 0 rgba(0,0,0,.15);';
      root.appendChild(desk);

      // 标题
      const t = document.createElement('div');
      t.textContent = '理发店 · 收银台';
      t.style.cssText = 'position:absolute;left:0;top:56px;width:100%;text-align:center;color:#fff;font-size:15px;opacity:.9;';
      desk.appendChild(t);

      // 办卡码（位置 40,280 尺寸140x140）
      const cardQR = makeQR(140, '办卡');
      cardQR.style.left = '40px';
      cardQR.style.top = '280px';
      root.appendChild(cardQR);

      const cardLabel = document.createElement('div');
      cardLabel.textContent = '办卡有礼';
      cardLabel.style.cssText = 'position:absolute;left:40px;top:426px;width:140px;text-align:center;font-size:13px;color:#6b5b49;';
      root.appendChild(cardLabel);

      // 单次付款码（位置 255,300 尺寸80x80）
      const singleQR = makeQR(80, '付款');
      singleQR.style.left = '255px';
      singleQR.style.top = '300px';
      root.appendChild(singleQR);

      const singleLabel = document.createElement('div');
      singleLabel.textContent = '单次付款';
      singleLabel.style.cssText = 'position:absolute;left:255px;top:386px;width:80px;text-align:center;font-size:13px;color:#6b5b49;';
      root.appendChild(singleLabel);

      // Tony 的手（持办卡单遮挡单次付款码）
      const hand = document.createElement('div');
      hand.style.cssText = 'position:absolute;width:120px;height:110px;background:#f6e7d4;border:2px solid #c9a06b;border-radius:10px 10px 4px 4px;box-shadow:0 3px 8px rgba(0,0,0,.2);z-index:5;';
      hand.innerHTML = '<div style="font-size:11px;color:#8a6d4a;text-align:center;padding-top:6px;">办卡单</div>';
      root.appendChild(hand);

      // Tony 气泡
      const tony = document.createElement('div');
      tony.className = 'bubble';
      tony.style.cssText += 'left:150px;top:18px;';
      tony.textContent = '办卡打五折';
      root.appendChild(tony);

      const tonyWords = ['办卡打五折', '充值送护理'];
      let wi = 0;
      const tonyTimer = setInterval(function () {
        wi = (wi + 1) % tonyWords.length;
        tony.textContent = tonyWords[wi];
      }, 1800);

      // 手机
      const phone = document.createElement('div');
      phone.style.cssText = 'position:absolute;width:90px;height:150px;background:#2b2b2b;border-radius:14px;box-shadow:0 4px 14px rgba(0,0,0,.35);z-index:10;touch-action:none;';
      phone.innerHTML = '<div style="position:absolute;left:14px;top:26px;width:62px;height:34px;background:#e8f4ff;border-radius:6px;text-align:center;line-height:34px;font-size:11px;color:#333;">扫码</div>';
      root.appendChild(phone);

      // 手机中心下方的小三角（扫码点）
      const tip = document.createElement('div');
      tip.style.cssText = 'position:absolute;left:50%;bottom:8px;width:0;height:0;border-left:7px solid transparent;border-right:7px solid transparent;border-top:10px solid #fff;transform:translateX(-50%);';
      phone.appendChild(tip);

      let phoneX = 142, phoneY = 430;
      function placePhone() {
        phone.style.left = phoneX + 'px';
        phone.style.top = phoneY + 'px';
      }
      placePhone();

      // 遮挡循环：遮挡1.5s，露出0.7s
      let blocking = true;
      function blockLoop() {
        const singleCenterX = 255 + 40, singleCenterY = 300 + 40;
        if (blocking) {
          // 盖住单次付款码
          hand.style.left = (singleCenterX - 60) + 'px';
          hand.style.top = (singleCenterY - 55) + 'px';
          hand.style.opacity = '1';
          blocking = false;
          setTimeout(blockLoop, 1500);
        } else {
          // 移开（露出来）
          hand.style.left = (singleCenterX - 60 + 140) + 'px';
          hand.style.top = (singleCenterY - 55 - 60) + 'px';
          hand.style.opacity = '.35';
          blocking = true;
          setTimeout(blockLoop, 700);
        }
      }
      blockLoop();

      // 手机拖动（坐标换算：把屏幕坐标转成 375×600 画布坐标）
      let dragging = false, ox = 0, oy = 0;
      function toCanvas(e) {
        // 用 stage 的 boundingRect 精确换算（PC 端画布被 CSS scale，H5 端画布铺满窗口）
        const el = G.stage || root;
        const r = el.getBoundingClientRect();
        return {
          x: (e.clientX - r.left) * (DESIGN_W / r.width),
          y: (e.clientY - r.top) * (DESIGN_W / r.width)
        };
      }
      phone.addEventListener('pointerdown', function (e) {
        dragging = true;
        const p = toCanvas(e);
        ox = p.x - phoneX;
        oy = p.y - phoneY;
        phone.setPointerCapture(e.pointerId);
        phone.style.zIndex = 30;
        G.beep(520, 0.05);
      });
      phone.addEventListener('pointermove', function (e) {
        if (!dragging) return;
        const p = toCanvas(e);
        phoneX = p.x - ox;
        phoneY = p.y - oy;
        placePhone();
      });
      phone.addEventListener('pointerup', function (e) {
        if (!dragging) return;
        dragging = false;
        phone.style.zIndex = 10;
        judge();
      });

      // 判定：手机中心下方 → 扫码点坐标 = 手机中心 + 向下(约 60px)
      function judge() {
        const scanX = phoneX + 45;
        const scanY = phoneY + 75 + 55; // 手机底部偏下
        const inCard = scanX >= 40 && scanX <= 180 && scanY >= 280 && scanY <= 420;
        const inSingle = scanX >= 255 && scanX <= 335 && scanY >= 300 && scanY <= 380;

        if (blocking === false && inSingle) {
          // 单次付款码露出时松手
          G.beep(720, 0.15);
          showResult('single');
        } else if (inCard || (blocking === true && inSingle)) {
          // 位于办卡码或办卡单上
          G.beep(320, 0.15);
          showResult('card');
        } else {
          // 没码：弹回原位
          phoneX = 142; phoneY = 430;
          phone.style.transition = 'left .3s, top .3s';
          placePhone();
          setTimeout(function () { phone.style.transition = ''; }, 300);
        }
      }

      function showResult(kind) {
        clearInterval(tonyTimer);
        const overlay = document.createElement('div');
        overlay.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;background:rgba(0,0,0,.55);z-index:100;display:flex;align-items:center;justify-content:center;';
        const box = document.createElement('div');
        box.style.cssText = 'background:#fff;border-radius:14px;padding:20px 28px;text-align:center;font-size:17px;box-shadow:0 6px 24px rgba(0,0,0,.3);';
        if (kind === 'single') {
          box.innerHTML = '<div style="font-size:22px;margin-bottom:6px;">✅</div>支付成功 ¥38';
          tony.textContent = '';
          hand.style.opacity = '0';
        } else {
          box.innerHTML = '<div style="font-size:22px;margin-bottom:6px;">💳</div>套餐列表';
          const list = document.createElement('div');
          list.style.cssText = 'font-size:13px;color:#666;margin:8px 0;line-height:1.7;';
          list.textContent = '烫染会员卡 ¥1280\n洗发十次卡 ¥680\n至尊黑金卡 ¥6888';
          box.appendChild(list);
        }
        overlay.appendChild(box);
        root.appendChild(overlay);

        setTimeout(function () {
          finish(kind);
        }, 1600);
      }

      return { root };
    }
  });

  // 装饰性二维码（Canvas，不可识别）
  function makeQR(size, label) {
    const c = document.createElement('canvas');
    c.width = c.height = size * 2;
    const ctx = c.getContext('2d');
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, size * 2, size * 2);
    // 三个定位角
    drawFinder(ctx, 0, 0, size);
    drawFinder(ctx, size * 2 - size * 0.35, 0, size);
    drawFinder(ctx, 0, size * 2 - size * 0.35, size);
    // 随机数据块
    const cell = size * 2 / 21;
    for (let y = 0; y < 21; y++) {
      for (let x = 0; x < 21; x++) {
        const inFinder = (x < 8 && y < 8) || (x >= 13 && y < 8) || (x < 8 && y >= 13);
        if (inFinder) continue;
        if (Math.random() < 0.45) {
          ctx.fillStyle = '#1a1a1a';
          ctx.fillRect(x * cell, y * cell, cell * 0.9, cell * 0.9);
        }
      }
    }
    c.style.cssText = 'position:absolute;border:6px solid #fff;border-radius:8px;box-shadow:0 2px 6px rgba(0,0,0,.15);';
    return c;
  }
  function drawFinder(ctx, ox, oy, size) {
    const s = size * 2 * 0.18;
    ctx.fillStyle = '#1a1a1a';
    ctx.fillRect(ox, oy, s, s);
    ctx.fillStyle = '#fff';
    ctx.fillRect(ox + s * 0.22, oy + s * 0.22, s * 0.56, s * 0.56);
    ctx.fillStyle = '#1a1a1a';
    ctx.fillRect(ox + s * 0.4, oy + s * 0.4, s * 0.2, s * 0.2);
  }
})();
