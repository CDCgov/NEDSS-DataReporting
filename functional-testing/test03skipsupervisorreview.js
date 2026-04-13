import { createRunner, PuppeteerRunnerExtension } from '@puppeteer/replay';
import puppeteer from 'puppeteer';
import fs from 'fs';
import readline from 'readline';


// pause after each step if run with argument "nopause":
// node test03skipsupervisorreview.js nopause
const stepPause = !process.argv.includes('nopause');

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const waitForEnter = (msg) => new Promise(resolve => rl.question(msg, resolve));

async function runFile(browser, page, file) {
  console.log(`Running ${file}...`);
  const recording = JSON.parse(fs.readFileSync(file, 'utf8'));
  const runner = await createRunner(recording, new PuppeteerRunnerExtension(browser, page));
  await runner.run();
}

const browser = await puppeteer.launch({ headless: false });
const page = await browser.newPage();


//
//
// step 01: create a patient and add a lab report manually
await runFile(browser, page, '010.CreatePatientSwift_fake55ee.json');
await runFile(browser, page, '012.AddLabReportManualSalmonella.json');

if (stepPause) {
  await waitForEnter('Step 01 complete. Press Enter to continue.');
}

//
//
// step 02: create an investigation
await runFile(browser, page, '020.CreateInvestigationSalmonella.json');

if (stepPause) {
  await waitForEnter('Step 02 complete. Press Enter to continue.');
}

//
//
// step 03: add information typical when investigating, including a treatment
await runFile(browser, page, '030.InvestigateSalmonella.json');


// click add treatment button. this triggers the treatment popup. 
// popups will require special handling to work correctly
await runFile(browser, page, '032.AddTreatmentStartSalmonella.json');

// function to wait for the popup
const newPagePromise = new Promise(resolve => 
  browser.once('targetcreated', async target => {
    const p = await target.page();
    await p.waitForLoadState?.('domcontentloaded');
    resolve(p);
  })
);

// wait for the treatment popup and fill it in
const newPage = await newPagePromise;
await newPage.bringToFront();
await newPage.waitForSelector('#NBS475CodeLookupButton', { visible: true });
await runFile(browser, newPage, '033.AddTreatmentPopupSalmonella.json');

// click submit on Manage Associations page to finish treatment addition
await runFile(browser, page, '034.AddTreatmentFinishSalmonella.json');

if (stepPause) {
  await waitForEnter('Step 03 complete. Press Enter to continue.');
}

//
//
// step 04: close the investigation and send the notification to CDC
await runFile(browser, page, '040.CloseInvestigationSalmonellaAndCreateNotification.json');

if (stepPause) {
  await waitForEnter('Step 04 complete. This is the last step. Press Enter to finish.');
}

rl.close();
await browser.close();


