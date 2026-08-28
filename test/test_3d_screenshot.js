/**
 * Playwright 截图测试 — 3D 厂区布置图
 * 截取多角度截图 + 布置合理性分析
 */
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://127.0.0.1:10010';
const SCREENSHOT_DIR = '/root/workspace/MoonDES/test/screenshots';

async function run() {
  if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });

  let browser;
  try {
    browser = await chromium.launch({
      headless: true,
      args: ['--no-sandbox','--disable-setuid-sandbox','--disable-gpu','--disable-dev-shm-usage','--enable-webgl','--use-gl=swiftshader','--ignore-gpu-blocklist']
    });

    const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
    const consoleErrors = [];
    page.on('console', msg => { if (msg.type() === 'error') consoleErrors.push(msg.text()); });

    console.log('1. 打开页面...');
    await page.goto(BASE_URL, { waitUntil: 'networkidle', timeout: 30000 });

    console.log('2. 切换到 3D 视图...');
    await page.locator('button.nav-btn:has-text("3D厂区视图")').click();
    await page.waitForTimeout(5000);

    const has3D = await page.evaluate(() => !!window.__three3d && !!window.__three3d.getCamera());
    console.log('   Three.js 初始化: ' + (has3D ? '✅' : '❌'));
    if (!has3D) { console.log('   ERROR:', consoleErrors); await browser.close(); return; }

    const camInfo = await page.evaluate(() => {
      var cam = window.__three3d.getCamera();
      var ctrl = window.__three3d.getControls();
      return { pos: [cam.position.x, cam.position.y, cam.position.z], meshCount: window.__three3d.getMeshes().length };
    });
    console.log('   相机: [' + camInfo.pos.map(v => v.toFixed(1)).join(', ') + '], 网格: ' + camInfo.meshCount);

    // 辅助函数：设置相机位置
    async function setCamera(x, y, z) {
      await page.evaluate(function(p) {
        var cam = window.__three3d.getCamera();
        var ctrl = window.__three3d.getControls();
        cam.position.set(p.x, p.y, p.z);
        ctrl.target.set(0, 0, 0);
        ctrl.update();
      }, { x: x, y: y, z: z });
      await page.waitForTimeout(1500);
    }

    // 辅助函数：截图
    async function shot(name) {
      await page.locator('#three3d-container').screenshot({ path: path.join(SCREENSHOT_DIR, name) });
    }

    // 截图 1: 默认视角
    console.log('3. 截图: 默认视角...');
    await page.waitForTimeout(2000);
    await shot('3d-01-default.png');

    // 截图 2: 俯视
    console.log('4. 截图: 俯视角...');
    await setCamera(0, 300, 0.1);
    await shot('3d-02-topdown.png');

    // 截图 3: 正面
    console.log('5. 截图: 正面...');
    await setCamera(0, 50, 300);
    await shot('3d-03-front.png');

    // 截图 4: 侧面
    console.log('6. 截图: 侧面...');
    await setCamera(300, 50, 0);
    await shot('3d-04-side.png');

    // 截图 5: 45度俯视
    console.log('7. 截图: 45度俯视...');
    await setCamera(150, 150, 150);
    await shot('3d-05-iso.png');

    // 截图 6: 低角度近景
    console.log('8. 截图: 近景...');
    await setCamera(80, 20, 80);
    await shot('3d-06-close.png');

    // 截图 7: 整页
    console.log('9. 截图: 整页...');
    await setCamera(200, 150, 200);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, '3d-07-fullpage.png'), fullPage: true });

    // 截图 8-13: 逐类高亮
    var categories = ['一级处理','二级处理','三级处理','污泥处理','辅助建筑','厂区设施'];
    for (var i = 0; i < categories.length; i++) {
      var catName = categories[i];
      console.log((10 + i) + '. 截图: 高亮 ' + catName + '...');

      // 用字符串注入避免参数传递问题
      await page.evaluate(function(cn) {
        var meshes = window.__three3d.getMeshes();
        meshes.forEach(function(m) {
          m.material.opacity = 0.12;
          m.material.transparent = true;
          m.material.color.set(m.userData.color);
        });
        meshes.forEach(function(m) {
          if (m.userData.category === cn) {
            m.material.opacity = 1.0;
          }
        });
      }, catName);

      await setCamera(150, 150, 150);
      var fname = '3d-' + String(8 + i).padStart(2, '0') + '-highlight.png';
      await shot(fname);
    }

    // 恢复所有 mesh
    await page.evaluate(function() {
      var meshes = window.__three3d.getMeshes();
      meshes.forEach(function(m) {
        m.material.opacity = 0.85;
        m.material.color.set(m.userData.color);
      });
    });

    // ===== 布置合理性分析 =====
    console.log('\n📊 3D 场景布置分析:');
    var analysis = await page.evaluate(function() {
      var meshes = window.__three3d.getMeshes();
      var results = [];
      for (var i = 0; i < meshes.length; i++) {
        var m = meshes[i];
        // 手动计算 bounding box — 不依赖 THREE
        var pos = m.geometry.attributes.position;
        var min = [Infinity, Infinity, Infinity];
        var max = [-Infinity, -Infinity, -Infinity];
        for (var j = 0; j < pos.count; j++) {
          var x = pos.getX(j), y = pos.getY(j), z = pos.getZ(j);
          if (x < min[0]) min[0] = x; if (y < min[1]) min[1] = y; if (z < min[2]) min[2] = z;
          if (x > max[0]) max[0] = x; if (y > max[1]) max[1] = y; if (z > max[2]) max[2] = z;
        }
        results.push({
          name: m.userData.name,
          label: m.userData.label,
          category: m.userData.category,
          cx: (min[0]+max[0])/2, cy: (min[1]+max[1])/2, cz: (min[2]+max[2])/2,
          sx: max[0]-min[0], sy: max[1]-min[1], sz: max[2]-min[2],
          vertices: pos.count
        });
      }
      return results;
    });

    // 输出构筑物表
    console.log('\n  序号  名称            位置(x,y,z)              尺寸(w,h,d)          类别');
    console.log('  ' + '─'.repeat(95));
    for (var i = 0; i < analysis.length; i++) {
      var a = analysis[i];
      var pos = '[' + a.cx.toFixed(1).padStart(6) + ',' + a.cy.toFixed(1).padStart(5) + ',' + a.cz.toFixed(1).padStart(6) + ']';
      var sz = '[' + a.sx.toFixed(1).padStart(5) + ',' + a.sy.toFixed(1).padStart(5) + ',' + a.sz.toFixed(1).padStart(5) + ']';
      console.log('  ' + String(i).padStart(2) + '  ' + a.label.padEnd(14) + pos + '  ' + sz + '  ' + a.category);
    }

    // 合理性检查
    console.log('\n🔍 合理性检查:');

    // 1. 重叠检测
    var overlaps = [];
    for (var i = 0; i < analysis.length; i++) {
      for (var j = i + 1; j < analysis.length; j++) {
        var a = analysis[i], b = analysis[j];
        var ox = Math.min(a.cx+a.sx/2, b.cx+b.sx/2) - Math.max(a.cx-a.sx/2, b.cx-b.sx/2);
        var oz = Math.min(a.cz+a.sz/2, b.cz+b.sz/2) - Math.max(a.cz-a.sz/2, b.cz-b.sz/2);
        var oy = Math.min(a.cy+a.sy/2, b.cy+b.sy/2) - Math.max(a.cy-a.sy/2, b.cy-b.sy/2);
        if (ox > 0.5 && oz > 0.5 && oy > 0.5) {
          overlaps.push(a.label + '↔' + b.label);
        }
      }
    }
    console.log('  重叠: ' + overlaps.length + ' 对' + (overlaps.length === 0 ? ' ✅' : ' ⚠️'));
    overlaps.slice(0, 8).forEach(function(o) { console.log('    ' + o); });

    // 2. 厂区范围
    var oob = analysis.filter(function(a) { return Math.abs(a.cx) > 50 || Math.abs(a.cz) > 35; });
    console.log('  超出厂区范围: ' + oob.length + (oob.length === 0 ? ' ✅' : ' ⚠️'));

    // 3. 工艺流向
    var prim = analysis.filter(function(a) { return a.category === '一级处理'; });
    var sec = analysis.filter(function(a) { return a.category === '二级处理'; });
    var tert = analysis.filter(function(a) { return a.category === '三级处理'; });
    var primX = prim.reduce(function(s,a){return s+a.cx},0) / prim.length;
    var secX = sec.reduce(function(s,a){return s+a.cx},0) / sec.length;
    var tertX = tert.reduce(function(s,a){return s+a.cx},0) / tert.length;
    console.log('  一级处理平均X: ' + primX.toFixed(1));
    console.log('  二级处理平均X: ' + secX.toFixed(1));
    console.log('  三级处理平均X: ' + tertX.toFixed(1));
    console.log('  工艺流向: ' + (primX < secX && secX < tertX ? '✅ 一级→二级→三级' : '⚠️ 流向需检查'));

    // 4. 零尺寸检测
    var zero = analysis.filter(function(a) { return a.sx < 0.1 || a.sy < 0.1 || a.sz < 0.1; });
    console.log('  零尺寸构筑物: ' + zero.length + (zero.length === 0 ? ' ✅' : ' ❌'));

    // 5. 类别统计
    var cats = {};
    analysis.forEach(function(a) { cats[a.category] = (cats[a.category]||0)+1; });
    console.log('  类别分布: ' + JSON.stringify(cats));

    // 6. 进出水方向
    var intake = analysis.find(function(a) { return a.label.indexOf('进水') >= 0; });
    var outlet = analysis.find(function(a) { return a.label.indexOf('出水') >= 0 || a.label.indexOf('排放') >= 0; });
    if (intake && outlet) {
      console.log('  进水检查井: [' + intake.cx.toFixed(1) + ',' + intake.cz.toFixed(1) + ']');
      console.log('  出水/排放: [' + outlet.cx.toFixed(1) + ',' + outlet.cz.toFixed(1) + ']');
      console.log('  进出水距离: ' + Math.sqrt(Math.pow(outlet.cx-intake.cx,2)+Math.pow(outlet.cz-intake.cz,2)).toFixed(1) + 'm');
    }

    // 列出截图
    console.log('\n📸 截图文件:');
    var files = fs.readdirSync(SCREENSHOT_DIR).filter(function(f) { return f.endsWith('.png'); }).sort();
    files.forEach(function(f) {
      var stat = fs.statSync(path.join(SCREENSHOT_DIR, f));
      console.log('  ' + f + ' (' + (stat.size/1024).toFixed(1) + ' KB)');
    });

    console.log('\n📋 Console 错误: ' + consoleErrors.length + ' 条');
    consoleErrors.slice(0, 5).forEach(function(e) { console.log('  ⚠️ ' + e); });

  } catch (err) {
    console.error('❌ 测试失败:', err.message, err.stack);
  } finally {
    if (browser) await browser.close();
  }
}

run();
