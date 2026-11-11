/* 第三关：验证码 */
(function () {
  window.registerLevel('captcha', {
    title: '验证码',
    results: {
      login: { title: '请完成实名认证' },
      locked: { title: '操作频繁，请明日再试' }
    },
    create(core, finish) {
      const root = document.createElement('div');
      root.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;overflow:hidden;background:#f0ede7;';
      core.appendChild(root);

      // 登录页
      const page = document.createElement('div');
      page.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;background:#f0ede7;';
      page.innerHTML =
        '<div style="position:absolute;left:0;top:130px;width:100%;text-align:center;font-size:22px;font-weight:600;">登录</div>' +
        '<div style="position:absolute;left:48px;top:200px;font-size:14px;color:#888;">手机号</div>' +
        '<input readonly style="position:absolute;left:48px;top:226px;width:279px;height:44px;border:1px solid #ccc;border-radius:8px;padding:0 12px;font-size:16px;background:#fff;" value="138****8888">' +
        '<div style="position:absolute;left:48px;top:290px;font-size:14px;color:#888;">验证码</div>';
      // 6格输入框
      const box = document.createElement('div');
      box.style.cssText = 'position:absolute;left:48px;top:316px;width:180px;height:44px;display:flex;';
      for (let i = 0; i < 6; i++) {
        const g = document.createElement('div');
        g.style.cssText = 'width:26px;height:40px;border:1px solid #ccc;border-radius:4px;margin-right:4px;background:#fff;font-size:18px;text-align:center;line-height:40px;';
        box.appendChild(g);
      }
      page.appendChild(box);

      const getBtn = document.createElement('div');
      getBtn.textContent = '获取验证码';
      getBtn.style.cssText = 'position:absolute;left:236px;top:316px;width:91px;height:44px;background:#c0392b;color:#fff;border-radius:8px;font-size:14px;text-align:center;line-height:44px;';
      page.appendChild(getBtn);
      root.appendChild(page);

      // 验证码值
      const code = String(Math.floor(100000 + Math.random() * 900000));

      // 横幅容器
      const bannerLayer = document.createElement('div');
      bannerLayer.style.cssText = 'position:absolute;left:0;top:0;width:375px;z-index:80;pointer-events:none;';
      root.appendChild(bannerLayer);

      const NOISE = ['双十一预热', '贷款待领取', '好友点赞', '今日特惠', '会员日红包', '游戏礼包'];
      const banners = []; // 当前活跃横幅
      let speed = 1; // 横幅速度倍率
      let missCount = 0; // 连续未命中
      let running = false;
      let lock = false;

      function spawnBanner(isCode) {
        const b = document.createElement('div');
        const isReal = isCode;
        b.style.cssText = 'width:343px;height:64px;margin:6px 16px 0;border-radius:12px;background:' +
          (isReal ? '#e74c3c' : '#fff') + ';color:' + (isReal ? '#fff' : '#333') +
          ';box-shadow:0 2px 10px rgba(0,0,0,.18);display:flex;align-items:center;padding:0 16px;font-size:15px;' +
          'position:relative;pointer-events:auto;transition:transform .25s;';
        const txt = isReal ? '验证码：' + code : NOISE[Math.floor(Math.random() * NOISE.length)];
        b.innerHTML = '<span style="flex:1;">' + txt + '</span>' +
          (isReal ? '<span style="font-size:12px;background:rgba(255,255,255,.3);padding:3px 8px;border-radius:10px;">填入</span>' : '');
        bannerLayer.appendChild(b);
        banners.push(b);
        reflow();

        // 停留 2 秒后消失
        setTimeout(function () {
          const i = banners.indexOf(b);
          if (i >= 0) banners.splice(i, 1);
          if (b.parentNode) b.remove();
          reflow();
        }, 2000 / speed);

        // 点击
        b.addEventListener('pointerdown', function () {
          if (lock) return;
          if (isReal) {
            // 命中验证码
            lock = true;
            fillCode();
            G.beep(760, 0.15);
            setTimeout(function () { showLogin(); }, 400);
          } else {
            // 未命中
            missCount++;
            G.beep(300, 0.1);
            if (missCount >= 3) {
              lock = true;
              showLocked();
            }
          }
        });
      }

      function reflow() {
        // 新横幅把旧横幅压下去（按顺序排列）
        banners.forEach(function (b, i) {
          b.style.transform = 'translateY(' + (i * 70) + 'px)';
        });
      }

      function fillCode() {
        const cells = box.children;
        for (let i = 0; i < 6; i++) {
          cells[i].textContent = code[i];
        }
      }

      // 获取验证码流程
      getBtn.addEventListener('pointerdown', function () {
        if (running || lock) return;
        running = true;
        getBtn.textContent = '发送中…';
        getBtn.style.background = '#bbb';
        const delay = (0.8 + Math.random() * 0.7) * 1000; // 0.8–1.5s
        setTimeout(function () {
          if (lock) return;
          // 连续弹出横幅
          let n = 0;
          const total = 6 + Math.floor(Math.random() * 3);
          const codeIdx = 2 + Math.floor(Math.random() * 3); // 验证码混在中间
          function emit() {
            if (n >= total) return;
            spawnBanner(n === codeIdx);
            n++;
            const gap = (600 / speed) * (0.7 + Math.random() * 0.6);
            setTimeout(emit, gap);
          }
          emit();
          getBtn.textContent = '重新获取（3）';
          running = false;
        }, delay);
      });

      function showLogin() {
        const ov = document.createElement('div');
        ov.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;background:rgba(0,0,0,.6);display:flex;align-items:center;justify-content:center;z-index:100;';
        ov.innerHTML = '<div style="background:#fff;border-radius:14px;padding:24px;width:300px;text-align:center;">' +
          '<div style="font-size:16px;margin-bottom:16px;">请完成实名认证</div>' +
          '<div style="width:220px;height:44px;line-height:44px;margin:0 auto;background:#c0392b;color:#fff;border-radius:8px;">获取验证码</div></div>';
        root.appendChild(ov);
        setTimeout(function () { finish('login'); }, 1600);
      }

      function showLocked() {
        const ov = document.createElement('div');
        ov.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;background:rgba(0,0,0,.6);display:flex;align-items:center;justify-content:center;z-index:100;';
        ov.innerHTML = '<div style="background:#fff;border-radius:14px;padding:24px;text-align:center;font-size:16px;">操作频繁，请明日再试</div>';
        root.appendChild(ov);
        setTimeout(function () { finish('locked'); }, 1600);
      }

      return { root };
    }
  });
})();
