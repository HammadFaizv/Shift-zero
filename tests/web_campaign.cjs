// Run tests/campaign.gd first. Uses only real desk controls in the release build.
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
  const inputs = JSON.parse(fs.readFileSync('/tmp/shift-zero-campaign-inputs.json', 'utf8'));
  const click = async point => {
    await page.mouse.click(...point);
    await page.waitForTimeout(400);
  };
  const shot = async name => page.screenshot({ path: `/tmp/shift-zero-web-campaign-${name}.png` });
  try {
    await page.goto(process.env.WEB_URL || 'http://127.0.0.1:8060/index.html');
    await page.waitForFunction(() => !document.querySelector('#status'), null, { timeout: 60000 });
    await page.waitForTimeout(1200);
    for (let index = 0; index < 5; index++) {
      const current = inputs[`case${index}`];
      console.log('Solving case', index + 1);
      await page.mouse.click(830, 620); // Focus an empty part of the desk.
      await page.keyboard.press('l');
      for (const tool of current.tools) {
        // Paperweights remain at their start poses in optical cases.
        if (index >= 2 && tool.name.startsWith('Paperweight')) continue;
        await page.mouse.move(...tool.from);
        await page.mouse.down();
        await page.mouse.move(...tool.to, { steps: 18 });
        await page.waitForTimeout(160);
        await page.mouse.up();
        if (tool.handle_from) {
          await page.mouse.move(...tool.handle_from);
          await page.mouse.down();
          await page.mouse.move(...tool.handle_to, { steps: 15 });
          await page.mouse.up();
        } else if (tool.name === 'Torch') {
          await page.mouse.wheel(0, -100);
        }
        await page.waitForTimeout(240);
      }
      await page.keyboard.press('Escape');
      await shot(`case${index + 1}-solved`);
      if (index === 4) {
        const cadence = await page.evaluate(() => new Promise(resolve => {
          const intervals = [];
          let previous = performance.now();
          function frame(now) {
            intervals.push(now - previous);
            previous = now;
            if (intervals.length < 120) requestAnimationFrame(frame);
            else resolve(intervals.reduce((sum, value) => sum + value, 0) / intervals.length);
          }
          requestAnimationFrame(frame);
        }));
        console.log('Solved train with redirector and focuser: mean frame interval ms', cadence);
      }
      await click(current.publish);
      if (index < 4) {
        await page.waitForTimeout(3900);
        await shot(`case${index + 1}-comic`);
        await click(inputs[`result${index}`].back);
        await shot(`case${index + 1}-returned`);
        await click(current.publish);
        await click(inputs[`result${index}`].next);
        await page.waitForTimeout(300);
      }
    }
    await shot('final-choice');
    await click(inputs.choices.cancel);
    await click(inputs.case4.publish);
    await click(inputs.choices.edited);
    await page.waitForTimeout(3900);
    await shot('ending-edited');
    await click(inputs.ending.replay);
    await click(inputs.ending.back);
    // The solved magnifier receives strong ceiling light, so test real time.
    await page.mouse.click(830, 620);
    await page.keyboard.press('l');
    await page.waitForTimeout(500);
    await shot('heat-warning');
    await page.waitForTimeout(2300);
    await shot('burned');
    await click(inputs.case4.publish);
    await click(inputs.choices.original);
    await page.waitForTimeout(3900);
    await shot('ending-original');
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.waitForTimeout(600);
    await shot('ending-wide');
    if (errors.length) throw new Error(errors.join('\n'));
    console.log('PASS: five release cases through real drag/rotation handles, transitions, printing/return, timed heat and both endings. Inspect screenshots for 4/4 states.');
  } catch (error) {
    await shot('error');
    console.error(errors);
    throw error;
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
