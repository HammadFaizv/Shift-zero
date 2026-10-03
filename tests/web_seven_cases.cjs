// Run tests/seven_cases.gd first to generate coordinates. No runtime test bridge.
const fs = require('fs');
const { chromium } = require('playwright-core');
(async () => {
 const browser = await chromium.launch({executablePath:'/usr/bin/google-chrome',headless:process.env.WEB_GPU!=='hardware',
  args:process.env.WEB_GPU==='hardware'?['--no-sandbox','--use-gl=angle','--use-angle=gl','--enable-gpu','--ignore-gpu-blocklist']:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const page=await browser.newPage({viewport:{width:1280,height:720}});
 const errors=[];
 page.on('pageerror',e=>errors.push(String(e)));
 page.on('console',m=>{if(m.type()==='error')errors.push(m.text());if(m.type()==='log')console.log('Game:',m.text());});
 const inputs=JSON.parse(fs.readFileSync('/tmp/shift-zero-seven-inputs.json','utf8'));
 const click=async p=>{await page.mouse.click(...p);await page.waitForTimeout(350);};
 const shot=async name=>page.screenshot({path:`/tmp/shift-zero-web-seven-${name}.png`});
 try {
  await page.goto(process.env.WEB_URL||'http://127.0.0.1:8060/index.html');
  await page.waitForFunction(()=>!document.querySelector('#status'),null,{timeout:60000});
  await page.waitForTimeout(1200);
  for(let index=0;index<7;index++) {
   console.log('Solving case',index+1);
   await shot(`case${index+1}-initial`);
   const data=inputs[`case${index}`];
   for(const tool of data.tools) {
    await page.mouse.move(...tool.from);await page.mouse.down();
    await page.mouse.move(...tool.to,{steps:18});await page.waitForTimeout(160);await page.mouse.up();
    if(tool.handle_from && Math.hypot(tool.handle_from[0]-tool.handle_to[0],tool.handle_from[1]-tool.handle_to[1])>1) {
     await page.mouse.move(...tool.handle_from);await page.mouse.down();
     await page.mouse.move(...tool.handle_to,{steps:18});await page.mouse.up();
    }
    await page.waitForTimeout(240);
   }
   await page.keyboard.press('Escape');await page.waitForTimeout(200);
   await shot(`case${index+1}-solved`);
   await click(data.publish);await page.waitForTimeout(3200);
   await shot(`case${index+1}-comic`);
   await click(inputs[`result${index}`].replay);await page.waitForTimeout(3200);
   await click(inputs[`result${index}`].back);await shot(`case${index+1}-returned`);
   await click(data.publish);await click(inputs[`result${index}`].next);await page.waitForTimeout(300);
  }
  await shot('sequence-return');
  await page.setViewportSize({width:1920,height:1080});await page.waitForTimeout(400);await shot('wide');
  if(errors.length)throw Error(errors.join('\n'));
  console.log('PASS: seven release cases through real drags/aim handles, printing, replay, returning and ordinary case progression.');
 }catch(e){await shot('error');throw e;}finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1);});
