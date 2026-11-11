/* 第四关：回T退订 */
(function () {
  window.registerLevel('unsubscribe', {
    title: '回T退订',
    results: {
      once: { title: '退订成功' },
      all_in: { title: '您已订阅全部服务' }
    },
    create(core, finish) {
      const root = document.createElement('div');
      root.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;overflow:hidden;background:#f0ede7;';
      core.appendChild(root);

      // 短信页
      const page = document.createElement('div');
      page.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:600px;background:#f0ede7;overflow:hidden;';
      root.appendChild(page);

      const header = document.createElement('div');
      header.textContent = '短信';
      header.style.cssText = 'position:absolute;left:0;top:0;width:375px;height:44px;line-height:44px;text-align:center;font-size:16px;font-weight:600;background:#fff;border-bottom:1px solid #eee;';
      page.appendChild(header);

      const list = document.createElement('div');
      list.style.cssText = 'position:absolute;left:0;top:44px;width:375px;height:480px;overflow:hidden;padding:12px;';
      page.appendChild(list);

      // 商家名
      const msgs = [
        { side: 'in', text: '新品上架，回T查看' },
        { side: 'in', text: '回T订阅会员日提醒' }
      ];

      // 输入框预填 T + 发送按钮
      const inputBar = document.createElement('div');
      inputBar.style.cssText = 'position:absolute;left:0;top:530px;width:375px;height:70px;background:#fff;border-top:1px solid #eee;display:flex;align-items:center;padding:0 12px;';
      const input = document.createElement('div');
      input.textContent = 'T';
      input.style.cssText = 'flex:1;height:40px;line-height:40px;border:1px solid #ccc;border-radius:20px;padding:0 16px;font-size:16px;background:#fafafa;color:#333;';
      const sendBtn = document.createElement('div');
      sendBtn.textContent = '发送';
      sendBtn.style.cssText = 'width:56px;height:44px;line-height:44px;margin-left:10px;background:#07c160;color:#fff;border-radius:8px;font-size:15px;text-align:center;';
      inputBar.appendChild(input);
      inputBar.appendChild(sendBtn);
      page.appendChild(inputBar);

      let sendCount = 0;
      let finished = false;

      const REPLIES = [
        ['退订成功', '感谢关注', '新品上架，回T查看'],
        ['已为您查看新品', '回T订阅会员日提醒'],
        ['您已订阅全部服务']
      ];

      function addMsg(side, text) {
        const row = document.createElement('div');
        row.style.cssText = 'margin:8px 0;display:flex;' + (side === 'out' ? 'justify-content:flex-end;' : 'justify-content:flex-start;');
        const bub = document.createElement('div');
        bub.textContent = text;
        bub.style.cssText = 'max-width:240px;padding:9px 14px;border-radius:14px;font-size:15px;line-height:1.4;background:' +
          (side === 'out' ? '#07c160;color:#fff;' : '#fff;color:#333;') +
          'box-shadow:0 1px 3px rgba(0,0,0,.08);';
        row.appendChild(bub);
        list.appendChild(row);
        list.scrollTop = list.scrollHeight;
      }

      function doSend() {
        if (finished) return;
        // 发送方气泡
        addMsg('out', 'T');
        sendCount++;

        const idx = Math.min(sendCount, 3) - 1;
        const replies = REPLIES[idx];
        let delay = 0;
        replies.forEach(function (t) {
          delay += 400;
          (function (txt) {
            setTimeout(function () {
              if (finished) return;
              addMsg('in', txt);
            }, delay);
          })(t);
        });

        // 重新填T
        input.textContent = 'T';

        if (sendCount >= 3) {
          // 发送按钮置灰
          sendBtn.style.background = '#ccc';
          finished = true;
          G.beep(320, 0.15);
          setTimeout(function () { finish('all_in'); }, 1500);
        }
      }

      sendBtn.addEventListener('pointerdown', doSend);

      // 发送1次后等待5秒 → once
      let onceTimer = null;
      function resetOnceTimer() {
        if (onceTimer) clearTimeout(onceTimer);
        if (finished) return;
        if (sendCount === 1) {
          onceTimer = setTimeout(function () {
            if (!finished) {
              finished = true;
              finish('once');
            }
          }, 5000);
        }
      }

      // 覆写 doSend 以启动计时
      const origSend = doSend;
      sendBtn.removeEventListener('pointerdown', doSend);
      sendBtn.addEventListener('pointerdown', function () {
        origSend();
        resetOnceTimer();
      });

      return { root };
    }
  });
})();
