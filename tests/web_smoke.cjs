// Run the native integration check first to produce matching input coordinates.
// NODE_PATH=/tmp/shift-zero-browser/node_modules node tests/web_smoke.cjs
const fs = require('fs');
const { chromium } = require('playwright-core');

(async () => {
  const browser = await chromium.launch({
    executablePath: process.env.CHROME_BINARY || '/usr/bin/google-chrome',
    headless: process.env.WEB_GPU !== 'hardware',
    args: process.env.WEB_GPU === 'hardware'
      ? ['--no-sandbox', '--use-gl=angle', '--use-angle=gl', '--enable-gpu', '--ignore-gpu-blocklist']
      : ['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  page.on('pageerror', error => errors.push(String(error)));
  page.on('console', message => {
    if (message.type() === 'error') errors.push(message.text());
    if (message.type() === 'log') console.log('Game:', message.text());
  });
  const inputs = JSON.parse(fs.readFileSync('/tmp/shift-zero-browser-inputs.json', 'utf8'));
  const click = async key => {
    await page.mouse.click(...inputs[key]);
    await page.waitForTimeout(600);
  };
  try {
    await page.goto(process.env.WEB_URL || 'http://127.0.0.1:8060/index.html');
    await page.waitForFunction(() => !document.querySelector('#status'), null, { timeout: 60000 });
    await page.waitForTimeout(1800);
    const renderer = await page.evaluate(() => {
      const gl = document.querySelector('canvas').getContext('webgl2');
      const debug = gl.getExtension('WEBGL_debug_renderer_info');
      return debug ? gl.getParameter(debug.UNMASKED_RENDERER_WEBGL) : 'WebGL2';
    });
    console.log('Browser renderer:', renderer);
    await page.screenshot({ path: '/tmp/shift-zero-web-desk.png' });
    await click('publish');
    await page.waitForTimeout(4400);
    await page.screenshot({ path: '/tmp/shift-zero-web-furious.png' });
    await click('replay');
    await page.screenshot({ path: '/tmp/shift-zero-web-replay.png' });
    await click('back');
    await page.screenshot({ path: '/tmp/shift-zero-web-return.png' });
    await page.mouse.click(430, 610); // Focus the desk canvas.
    await page.keyboard.press('l');
    for (const tool of inputs.tools) {
      await page.mouse.move(...tool.from);
      await page.mouse.down();
      await page.mouse.move(...tool.to, { steps: 20 });
      await page.waitForTimeout(250);
      await page.mouse.up();
      await page.waitForTimeout(250);
      if (tool.name === 'Torch') {
        await page.mouse.wheel(0, -100); // One 12-degree step restores yaw 0.
        await page.waitForTimeout(250);
      }
    }
    await page.keyboard.press('Escape');
    await page.screenshot({ path: '/tmp/shift-zero-web-solution.png' });
    const cadence = await page.evaluate(() => new Promise(resolve => {
      const times = [];
      let previous = performance.now();
      function frame(now) {
        times.push(now - previous);
        previous = now;
        if (times.length < 120) requestAnimationFrame(frame);
        else resolve({ meanMs: times.reduce((sum, value) => sum + value, 0) / times.length });
      }
      requestAnimationFrame(frame);
    }));
    console.log('Browser frame cadence:', JSON.stringify(cadence));
    await click('publish');
    await page.waitForTimeout(4400);
    await page.screenshot({ path: '/tmp/shift-zero-web-adoring.png' });
    await click('back');
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.waitForTimeout(700);
    await page.screenshot({ path: '/tmp/shift-zero-web-1920.png' });
    if (errors.length) throw new Error(errors.join('\n'));
    console.log('PASS: Web startup, publish/replay/return, drag/rotate solution, and resize without browser or Godot errors. Inspect saved screenshots for states.');
  } catch (error) {
    await page.screenshot({ path: '/tmp/shift-zero-web-error.png' });
    console.error('Browser errors:', errors, 'Status:', await page.evaluate(() => document.querySelector('#status')?.innerText || 'Game loaded'));
    throw error;
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
