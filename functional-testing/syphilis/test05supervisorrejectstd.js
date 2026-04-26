import { createRunner, PuppeteerRunnerExtension } from '@puppeteer/replay';
import puppeteer from 'puppeteer';
import fs from 'fs';
import readline from 'readline';


// pause after each step if run with argument "nopause":
// node test05supervisorrejectstd.js nopause
const stepPause = !process.argv.includes('nopause');

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const waitForEnter = (msg) => new Promise(resolve => rl.question(msg, resolve));

async function runFile(browser, page, file) {
  console.log(`Running ${file}...`);
  const recording = JSON.parse(fs.readFileSync(file, 'utf8'));
  const runner = await createRunner(recording, new PuppeteerRunnerExtension(browser, page));
  await runner.run();
}

async function runFileSlowly(browser, page, file) {
  console.log(`Running ${file} slowly...`);
  const client = await page.target().createCDPSession();
  await client.send('Emulation.setCPUThrottlingRate', { rate: 20 }); // 20x slower
  const recording = JSON.parse(fs.readFileSync(file, 'utf8'));
  const runner = await createRunner(recording, new PuppeteerRunnerExtension(browser, page));
  await runner.run();
  await client.send('Emulation.setCPUThrottlingRate', { rate: 1 }); // back to normal
}

//const browser = await puppeteer.launch({ headless: false, slowMo: 20 });
const browser = await puppeteer.launch({ headless: false });
const page = await browser.newPage();


//
//
// step 01: create a patient and add a lab report manually
await runFile(browser, page, '010.CreatePatientSwift_fake77gg.json');
await runFile(browser, page, '015.CreateLabReportSyphilis.json');

if (stepPause) {
  await waitForEnter('Step 01 complete. Press Enter to continue.');
}

//
//
// step 02: create an investigation
await runFile(browser, page, '020.CreateInvestigationSyphilis.json');

// function to wait for the popup
function waitForPopup() {
  return new Promise(resolve =>
    browser.once('targetcreated', async target => {
      const page = await target.page();
      await page.waitForLoadState?.('domcontentloaded');
      resolve(page);
    })
  );
}

// wait for the processing decision popup and fill it in
const decisionPage = await waitForPopup();
await decisionPage.bringToFront();
await runFile(browser, decisionPage, '022.CreateInvestigationProcessingDecisionPopup.json');

// finish creating the investigation
await runFile(browser, page, '024.CreateInvestigationSyphilisAssignInvestigator.json');

if (stepPause) {
  await waitForEnter('Step 02 complete. Press Enter to continue.');
}


//
//
// step 03: add a treatment
await runFile(browser, page, '030.AddTreatmentSyphilis.json');
const treatmentPage = await waitForPopup();
await treatmentPage.bringToFront();
await runFile(browser, treatmentPage, '035.AddTreatmentSyphilisPopup.json');
await runFile(browser, page, '037.AddTreatmentSubmit.json');

if (stepPause) {
  await waitForEnter('Step 03 complete. Press Enter to continue.');
}

//
//
// step 04: initial investigation and followup with reporting provider
await runFile(browser, page, '040.InvestigateSyphilisInitialFollowup.json');
if (stepPause) {
  await waitForEnter('Step 040 complete. Press Enter to continue.');
}

//
//
// step 05: assign investigator for field followup
await runFileSlowly(browser, page, '050.InvestigateSyphilisAssignFieldFollowup.json');
if (stepPause) {
  await waitForEnter('Step 04.2 complete. Press Enter to continue.');
}

/*
rl.close();
await browser.close();
*/


