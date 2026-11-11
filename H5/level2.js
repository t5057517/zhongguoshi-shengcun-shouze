/* 第二关：我只是想关掉它（开屏广告 + 卸载） */
(function () {
  window.registerLevel('uninstall', {
    title: '我只是想关掉它',
    results: {
      uninstalled: { title: '卸载成功' },
      converted: { title: '已被转化' }
    },
    create(core, finish) {
      const root = document.createElement('div');
      root.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;overflow:hidden;background:#f0ede7;';
      core.appendChild(root);

      let misTaps = 0; // 累计误触
      const MAX_MIS = 3;

      // ---------- 阶段1：开屏广告 ----------
      function stage1() {
        const ad = document.createElement('div');
        ad.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;background:linear-gradient(135deg,#ff7e5f,#feb47b);overflow:hidden;touch-action:none;z-index:50;';
        ad.innerHTML =
          '<div style="position:absolute;left:0;top:90px;width:100%;text-align:center;color:#fff;font-size:34px;font-weight:700;">爆款APP</div>' +
          '<div style="position:absolute;left:0;top:150px;width:100%;text-align:center;color:#fff;font-size:16px;opacity:.9;">点击立即下载 领新人红包</div>' +
          '<div style="position:absolute;left:0;top:210px;width:100%;text-align:center;font-size:90px;">📱</div>';
        root.appendChild(ad);

        // 中央 ×（尺寸64，点击跳转→即误触，走陷阱）
        const closeBtn = document.createElement('div');
        closeBtn.textContent = '×';
        closeBtn.style.cssText = 'position:absolute;left:50%;top:320px;width:64px;height:64px;margin-left:-32px;background:rgba(0,0,0,.35);color:#fff;border-radius:50%;font-size:42px;line-height:60px;text-align:center;z-index:60;';
        ad.appendChild(closeBtn);
        closeBtn.addEventListener('pointerdown', function () { trap(); });

        // 跳过5（位置295,16 尺寸64x28，归零才能点）
        const skip = document.createElement('div');
        skip.textContent = '跳过 5';
        skip.style.cssText = 'position:absolute;left:295px;top:16px;width:64px;height:28px;background:rgba(0,0,0,.4);color:#fff;border-radius:14px;font-size:13px;text-align:center;line-height:28px;z-index:60;';
        ad.appendChild(skip);
        let skipN = 5, skipReady = false;
        const skipTimer = setInterval(function () {
          skipN--;
          if (skipN <= 0) {
            skipN = 0; skipReady = true;
            skip.textContent = '跳过';
            clearInterval(skipTimer);
          } else {
            skip.textContent = '跳过 ' + skipN;
          }
        }, 1000);
        skip.addEventListener('pointerdown', function () {
          if (skipReady) toStage2();
        });

        // 灰色小点（位置16,16 视觉10px 热区28x28）
        const dot = document.createElement('div');
        dot.style.cssText = 'position:absolute;left:16px;top:16px;width:10px;height:10px;background:#888;border-radius:50%;z-index:60;';
        const dotHot = document.createElement('div');
        dotHot.style.cssText = 'position:absolute;left:7px;top:7px;width:28px;height:28px;z-index:61;';
        dotHot.appendChild(dot);
        ad.appendChild(dotHot);
        dotHot.addEventListener('pointerdown', function () { toStage2(); });

        // 滑动陷阱：移动超30px跳转（误触）
        let sx = 0, sy = 0, moved = 0;
        ad.addEventListener('pointerdown', function (e) {
          sx = e.clientX; sy = e.clientY; moved = 0;
        });
        ad.addEventListener('pointermove', function (e) {
          if (sx === null) return;
          const dx = e.clientX - sx, dy = e.clientY - sy;
          moved = Math.max(moved, Math.sqrt(dx * dx + dy * dy));
          if (moved > 30) {
            sx = null;
            trap();
          }
        });

        // 跳转演出：购物页1.5s后重新开始阶段1
        function trap() {
          misTaps++;
          G.beep(300, 0.12);
          if (misTaps >= MAX_MIS) {
            showConverted();
            return;
          }
          ad.innerHTML = '<div style="position:absolute;left:0;top:0;width:375px;height:600px;background:#fff;"></div>' +
            '<div style="position:absolute;left:0;top:120px;width:100%;text-align:center;font-size:22px;">🛍️ 购物页</div>' +
            '<div style="position:absolute;left:0;top:170px;width:100%;text-align:center;color:#999;">跳转中…</div>';
          ad.style.pointerEvents = 'none';
          clearInterval(skipTimer);
          setTimeout(function () {
            ad.remove();
            stage1();
          }, 1500);
        }

        function toStage2() {
          clearInterval(skipTimer);
          ad.remove();
          stage2();
        }
      }

      // ---------- 阶段2：卸载 ----------
      function stage2() {
        const popup = makePopup(
          '确定要卸载吗？',
          '再想想',
          '残忍卸载',
          function () {
            // 亮色按钮：返回弹窗1
            popup.remove();
            stage2();
          },
          function () {
            popup.remove();
            stage2b();
          }
        );
        root.appendChild(popup);
      }

      function stage2b() {
        const popup = makePopup(
          '卸载将失去3张优惠券',
          '保留优惠券',
          '仍然卸载',
          function () {
            popup.remove();
            stage2(); // 返回弹窗1
          },
          function () {
            // 完成卸载
            G.beep(720, 0.15);
            showUninstalled();
          }
        );
        root.appendChild(popup);
      }

      function makePopup(title, brightText, greyText, onBright, onGrey) {
        const wrap = document.createElement('div');
        wrap.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;background:rgba(0,0,0,.5);display:flex;align-items:center;justify-content:center;z-index:70;';
        const box = document.createElement('div');
        box.style.cssText = 'background:#fff;border-radius:14px;padding:24px;width:290px;text-align:center;box-shadow:0 8px 28px rgba(0,0,0,.3);';
        box.innerHTML = '<div style="font-size:16px;margin-bottom:22px;">' + title + '</div>';
        const bright = document.createElement('div');
        bright.textContent = brightText;
        bright.style.cssText = 'width:240px;height:48px;line-height:48px;margin:0 auto 12px;background:#c0392b;color:#fff;border-radius:24px;font-size:16px;';
        box.appendChild(bright);
        const grey = document.createElement('div');
        grey.textContent = greyText;
        grey.style.cssText = 'font-size:13px;color:#999;margin-top:4px;';
        box.appendChild(grey);
        wrap.appendChild(box);
        bright.addEventListener('pointerdown', onBright);
        grey.addEventListener('pointerdown', onGrey);
        return wrap;
      }

      function showConverted() {
        const ov = document.createElement('div');
        ov.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;background:rgba(0,0,0,.6);display:flex;align-items:center;justify-content:center;z-index:100;';
        ov.innerHTML = '<div style="color:#fff;font-size:22px;">已被转化</div>';
        root.appendChild(ov);
        setTimeout(function () { finish('converted'); }, 1500);
      }

      function showUninstalled() {
        // 静止1秒 → 猜你喜欢
        const ov = document.createElement('div');
        ov.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;background:#fff;display:flex;align-items:center;justify-content:center;z-index:100;';
        ov.innerHTML = '<div style="text-align:center;"><div style="font-size:50px;margin-bottom:10px;">🗑️</div><div style="font-size:18px;">正在卸载…</div></div>';
        root.appendChild(ov);
        setTimeout(function () {
          ov.innerHTML = '<div style="text-align:center;width:320px;"><div style="font-size:16px;margin-bottom:16px;">猜你喜欢</div>' +
            '<div style="width:80px;height:80px;margin:0 auto;border-radius:18px;background:linear-gradient(135deg,#ff7e5f,#feb47b);display:flex;align-items:center;justify-content:center;font-size:40px;">📱</div>' +
            '<div style="font-size:13px;color:#666;margin-top:8px;">爆款APP · 安装</div></div>';
          setTimeout(function () { finish('uninstalled'); }, 1400);
        }, 1000);
      }

      stage1();
      return { root };
    }
  });
})();
