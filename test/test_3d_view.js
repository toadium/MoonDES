/**
 * Playwright E2E Test — 污水处理厂 3D 厂区视图 (Three.js)
 */
const { chromium } = require('playwright');
const BASE_URL = 'http://127.0.0.1:10010';
const TIMEOUT = 30000;
const results = [];
let passCount = 0, failCount = 0;

function check(name, condition, detail) {
  detail = detail || '';
  if (condition) { passCount++; results.push('  ✅ ' + name + (detail ? ' — ' + detail : '')); }
  else { failCount++; results.push('  ❌ ' + name + (detail ? ' — ' + detail : '')); }
}

async function run() {
  let browser;
  const consoleErrors = [];
  const networkLogs = [];
  try {
    browser = await chromium.launch({
      headless: true,
      args: ['--no-sandbox','--disable-setuid-sandbox','--disable-gpu','--disable-dev-shm-usage','--enable-webgl','--use-gl=swiftshader','--ignore-gpu-blocklist']
    });
    var context = await browser.newContext({ viewport: { width: 1280, height: 900 }, ignoreHTTPSErrors: true });
    var page = await context.newPage();
    page.on('console', function(msg) { if (msg.type() === 'error') consoleErrors.push(msg.text()); });
    page.on('response', function(resp) { if (resp.url().includes('/api/')) networkLogs.push({ url: resp.url().replace(BASE_URL, ''), status: resp.status() }); });

    // TEST 1: 页面加载
    console.log('\n📋 TEST 1: 页面加载');
    await page.goto(BASE_URL, { waitUntil: 'networkidle', timeout: TIMEOUT });
    var title = await page.title();
    check('页面加载成功', title.includes('污水处理厂'), 'title="' + title + '"');

    // TEST 2: 3D 导航按钮
    console.log('📋 TEST 2: 3D 导航按钮');
    var navBtn3D = page.locator('button.nav-btn:has-text("3D厂区视图")');
    var btnCount = await navBtn3D.count();
    check('3D导航按钮存在', btnCount === 1, 'count=' + btnCount);
    var allNavBtns = await page.locator('button.nav-btn').allTextContents();
    check('导航栏有6个按钮', allNavBtns.length === 6, 'buttons=[' + allNavBtns.map(function(b){return b.trim()}).join(', ') + ']');

    // TEST 3: 切换到 3D 视图
    console.log('📋 TEST 3: 切换到 3D 视图');
    await navBtn3D.click();
    await page.waitForTimeout(3000);
    var isActive = await page.locator('#scene3d').evaluate(function(el) { return el.classList.contains('active'); });
    check('3D section 激活', isActive);

    // TEST 4: Three.js + WebGL Canvas
    console.log('📋 TEST 4: Three.js + WebGL Canvas');
    var canvasCount = await page.locator('#three3d-container canvas').count();
    check('WebGL canvas 创建', canvasCount >= 1, 'canvas count=' + canvasCount);
    var hasWebGL = await page.evaluate(function() {
      var canvas = document.querySelector('#three3d-container canvas');
      if (!canvas) return false;
      var gl = canvas.getContext('webgl') || canvas.getContext('webgl2') || canvas.getContext('experimental-webgl');
      return !!gl;
    });
    check('WebGL 上下文可用', hasWebGL);
    var canvasDims = await page.evaluate(function() {
      var c = document.querySelector('#three3d-container canvas');
      return c ? { w: c.width, h: c.height } : { w: 0, h: 0 };
    });
    check('Canvas 有有效尺寸', canvasDims.w > 0 && canvasDims.h > 0, canvasDims.w + 'x' + canvasDims.h);

    // TEST 5: /api/scene3d 数据验证
    console.log('📋 TEST 5: /api/scene3d 数据');
    var sceneResponse = await page.evaluate(async function() {
      var res = await fetch('/api/scene3d');
      return { status: res.status, data: await res.json() };
    });
    check('/api/scene3d 返回 200', sceneResponse.status === 200);
    var sceneData = sceneResponse.data;
    check('meshCount=40', sceneData.meshCount === 40, 'got=' + sceneData.meshCount);
    check('totalVertices=842', sceneData.totalVertices === 842, 'got=' + sceneData.totalVertices);
    check('totalFaces=1524', sceneData.totalFaces === 1524, 'got=' + sceneData.totalFaces);
    var bbox = sceneData.bbox;
    check('bbox 有效', bbox.length === 6 && bbox[0] < bbox[3] && bbox[1] < bbox[4] && bbox[2] < bbox[5], '[' + bbox.join(', ') + ']');
    var categories = sceneData.categories;
    check('6类配色', categories.length === 6, 'got=' + categories.length);
    var expectedCats = ['一级处理','二级处理','三级处理','污泥处理','辅助建筑','厂区设施'];
    var actualCatNames = categories.map(function(c){return c.name});
    check('类别名称正确', expectedCats.every(function(c){return actualCatNames.indexOf(c) >= 0}), 'actual=[' + actualCatNames.join(', ') + ']');
    var meshDataValid = true;
    for (var i = 0; i < sceneData.meshes.length; i++) {
      var m = sceneData.meshes[i];
      if (!m.vertices || !m.faces || !m.color || !m.label || !m.category || !m.name) { meshDataValid = false; break; }
    }
    check('每个 mesh 数据完整', meshDataValid, sceneData.meshes.length + ' meshes all valid');
    var firstMesh = sceneData.meshes[0];
    var lastMesh = sceneData.meshes[sceneData.meshes.length - 1];
    check('第一个 mesh=geometry_0', firstMesh.name === 'geometry_0', 'name="' + firstMesh.name + '", label="' + firstMesh.label + '"');
    check('最后一个 mesh=geometry_39', lastMesh.name === 'geometry_39', 'name="' + lastMesh.name + '", label="' + lastMesh.label + '"');
    var catCounts = {};
    sceneData.meshes.forEach(function(m) { catCounts[m.category] = (catCounts[m.category] || 0) + 1; });
    check('一级处理=6', catCounts['一级处理'] === 6, 'got=' + catCounts['一级处理']);
    check('二级处理=7', catCounts['二级处理'] === 7, 'got=' + catCounts['二级处理']);
    check('厂区设施=12', catCounts['厂区设施'] === 12, 'got=' + catCounts['厂区设施']);

    // TEST 6: /api/obj 数据验证
    console.log('📋 TEST 6: /api/obj 数据');
    var objResponse = await page.evaluate(async function() {
      var res = await fetch('/api/obj');
      return { status: res.status, text: await res.text() };
    });
    check('/api/obj 返回 200', objResponse.status === 200);
    check('OBJ 包含 o 指令', objResponse.text.indexOf('\no ') >= 0);
    check('OBJ 包含 v 指令', objResponse.text.indexOf('\nv ') >= 0);
    check('OBJ 包含 f 指令', objResponse.text.indexOf('\nf ') >= 0);
    var objObjectCount = (objResponse.text.match(/\no /g) || []).length;
    check('OBJ 有 40 个对象', objObjectCount === 40, 'count=' + objObjectCount);

    // TEST 7: 图例显示
    console.log('📋 TEST 7: 构筑物图例');
    var legendItems = await page.locator('#scene3d-legend > div').count();
    check('图例有 6 项', legendItems === 6, 'count=' + legendItems);
    var legendTexts = await page.locator('#scene3d-legend > div').allTextContents();
    check('图例包含一级处理', legendTexts.some(function(t){return t.indexOf('一级处理') >= 0}));
    check('图例包含污泥处理', legendTexts.some(function(t){return t.indexOf('污泥处理') >= 0}));

    // TEST 8: 场景信息标签
    console.log('📋 TEST 8: 场景信息标签');
    var infoBadge = await page.locator('#scene3d-info').textContent();
    check('信息标签显示构筑物数', infoBadge.indexOf('40') >= 0, 'text="' + infoBadge + '"');
    check('信息标签显示顶点数', infoBadge.indexOf('842') >= 0, 'text="' + infoBadge + '"');

    // TEST 9: OrbitControls 鼠标交互
    console.log('📋 TEST 9: OrbitControls 鼠标交互');
    var canvas = page.locator('#three3d-container canvas');
    var canvasBox = await canvas.boundingBox();
    if (canvasBox) {
      var cx = canvasBox.x + canvasBox.width / 2;
      var cy = canvasBox.y + canvasBox.height / 2;
      var snap1 = await page.evaluate(function() { return document.querySelector('#three3d-container canvas').toDataURL(); });
      await page.mouse.move(cx, cy);
      await page.mouse.down();
      await page.mouse.move(cx + 100, cy + 50, { steps: 10 });
      await page.mouse.up();
      await page.waitForTimeout(500);
      var snap2 = await page.evaluate(function() { return document.querySelector('#three3d-container canvas').toDataURL(); });
      check('鼠标旋转改变视图', snap1 !== snap2, 'canvas changed after drag');
      await page.mouse.move(cx, cy);
      await page.mouse.wheel(0, -300);
      await page.waitForTimeout(500);
      var snap3 = await page.evaluate(function() { return document.querySelector('#three3d-container canvas').toDataURL(); });
      check('滚轮缩放改变视图', snap2 !== snap3, 'canvas changed after zoom');
      await page.mouse.move(cx, cy);
      await page.mouse.down({ button: 'right' });
      await page.mouse.move(cx + 50, cy + 30, { steps: 5 });
      await page.mouse.up({ button: 'right' });
      await page.waitForTimeout(500);
      var snap4 = await page.evaluate(function() { return document.querySelector('#three3d-container canvas').toDataURL(); });
      check('右键平移改变视图', snap3 !== snap4, 'canvas changed after pan');
    } else {
      check('Canvas boundingBox 可用', false, 'null');
    }

    // TEST 10: 点击构筑物高亮
    console.log('📋 TEST 10: 点击构筑物高亮');
    if (canvasBox) {
      await page.mouse.click(canvasBox.x + canvasBox.width / 2, canvasBox.y + canvasBox.height / 2);
      await page.waitForTimeout(1000);
      var detailContent = await page.locator('#scene3d-detail').innerHTML();
      check('点击后信息面板有内容', detailContent.length > 10, 'len=' + detailContent.length);
      var hasName = detailContent.indexOf('处理') >= 0 || detailContent.indexOf('池') >= 0 ||
        detailContent.indexOf('泵') >= 0 || detailContent.indexOf('格栅') >= 0 ||
        detailContent.indexOf('井') >= 0 || detailContent.indexOf('房') >= 0 ||
        detailContent.indexOf('泥') >= 0 || detailContent.indexOf('道') >= 0;
      check('信息面板显示构筑物名称', hasName, 'content="' + detailContent.slice(0, 80) + '"');
      check('信息面板显示类别', detailContent.indexOf('类别') >= 0);
    }

    // TEST 11: 窗口 resize
    console.log('📋 TEST 11: 窗口 resize');
    var sizeBefore = await page.evaluate(function() { var c = document.querySelector('#three3d-container canvas'); return { w: c.width, h: c.height }; });
    await page.setViewportSize({ width: 800, height: 600 });
    await page.waitForTimeout(1000);
    var sizeAfter = await page.evaluate(function() { var c = document.querySelector('#three3d-container canvas'); return { w: c.width, h: c.height }; });
    check('resize 后 canvas 尺寸变化', sizeAfter.w !== sizeBefore.w || sizeAfter.h !== sizeBefore.h, 'before=' + sizeBefore.w + 'x' + sizeBefore.h + ', after=' + sizeAfter.w + 'x' + sizeAfter.h);
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.waitForTimeout(500);

    // TEST 12: 其他导航不受影响
    console.log('📋 TEST 12: 其他导航功能');
    await page.locator('button.nav-btn:has-text("总览看板")').click();
    await page.waitForTimeout(500);
    var ovActive = await page.locator('#overview').evaluate(function(el) { return el.classList.contains('active'); });
    check('切回总览看板', ovActive);
    await page.locator('button.nav-btn:has-text("工艺流程")').click();
    await page.waitForTimeout(500);
    var procActive = await page.locator('#process').evaluate(function(el) { return el.classList.contains('active'); });
    check('切换到工艺流程', procActive);
    await page.locator('button.nav-btn:has-text("3D厂区视图")').click();
    await page.waitForTimeout(2000);
    var sceneActiveAgain = await page.locator('#scene3d').evaluate(function(el) { return el.classList.contains('active'); });
    check('再次切换到3D视图', sceneActiveAgain);

    // TEST 13: 无 JS Console 错误
    console.log('📋 TEST 13: JS Console 错误');
    var realErrors = consoleErrors.filter(function(e) {
      return e.indexOf('deprecated') < 0 && e.indexOf('THREE.WebGLRenderer') < 0 &&
        e.indexOf('shader') < 0 && e.indexOf('SWIFTSHADER') < 0;
    });
    check('无 JS Console 错误', realErrors.length === 0, realErrors.length > 0 ? 'errors=[' + realErrors.slice(0, 3).join('; ') + ']' : '');

    // TEST 14: 网络请求
    console.log('📋 TEST 14: 网络请求');
    var scene3dCalls = networkLogs.filter(function(l) { return l.url === '/api/scene3d'; });
    check('/api/scene3d 被请求', scene3dCalls.length >= 1, 'calls=' + scene3dCalls.length);
    check('/api/scene3d 返回 200', scene3dCalls.every(function(c) { return c.status === 200; }));

    // TEST 15: 3D 渲染像素验证
    console.log('📋 TEST 15: 3D 渲染像素验证');
    var screenshot = await canvas.screenshot();
    check('canvas 截图成功', screenshot.length > 1000, 'size=' + screenshot.length + ' bytes');
    // 检查截图不是全黑（有 3D 内容）
    var pixelData = await page.evaluate(function() {
      var c = document.querySelector('#three3d-container canvas');
      var ctx = c.getContext('2d');
      if (!ctx) return { nonBg: 0, total: 0 };
      var imgData = ctx.getImageData(0, 0, c.width, c.height).data;
      var nonBg = 0, total = imgData.length / 4;
      for (var i = 0; i < imgData.length; i += 4) {
        var r = imgData[i], g = imgData[i+1], b = imgData[i+2];
        if (r > 15 || g > 20 || b > 30) nonBg++;
      }
      return { nonBg: nonBg, total: total };
    });
    check('canvas 有非背景像素', pixelData.nonBg > 0, 'nonBg=' + pixelData.nonBg + '/' + pixelData.total + ' (' + (pixelData.total > 0 ? (pixelData.nonBg / pixelData.total * 100).toFixed(1) : 0) + '%)');

  } catch (err) {
    check('测试执行无异常', false, err.message);
  } finally {
    if (browser) await browser.close();
  }

  // 输出结果
  console.log('\n' + '═'.repeat(70));
  console.log('  3D 厂区视图 Playwright 测试结果');
  console.log('═'.repeat(70));
  results.forEach(function(r) { console.log(r); });
  console.log('═'.repeat(70));
  console.log('  ✅ 通过: ' + passCount + '  ❌ 失败: ' + failCount + '  总计: ' + (passCount + failCount));
  console.log('═'.repeat(70));
  process.exit(failCount > 0 ? 1 : 0);
}

run();
