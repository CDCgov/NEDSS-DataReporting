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


// step 01: create a patient
await runFile(browser, page, '010.CreatePatient.json');

if (stepPause) {
  await waitForEnter('Step 01 complete. Press Enter to continue.');
}

// step 02: create an investigation
await runFile(browser, page, '020.AddInvestigationHepatitisA.json');

if (stepPause) {
  await waitForEnter('Step 02 complete. Press Enter to continue.');
}

// step 03: Create notification (launches a pop)
await runFile(browser, page, '030.CreateNotification.json');

// function to wait for the popup
const newPagePromise = new Promise(resolve => 
  browser.once('targetcreated', async target => {
    const p = await target.page();
    await p.waitForLoadState?.('domcontentloaded');
    resolve(p);
  })
);

// wait for the notification popup and fill it in
const newPage = await newPagePromise;
await newPage.bringToFront();
await newPage.waitForSelector('#NTF137', { visible: true });
await runFile(browser, newPage, '031.SubmitNotification.json');

if (stepPause) {
  await waitForEnter('Step 03 complete. Press Enter to continue.');
}

// step 04: approve the notification
await runFile(browser, page, '040.ApproveNotification.json');

// function to wait for the popup
const approvalPopup = new Promise(resolve => 
  browser.once('targetcreated', async target => {
    const p = await target.page();
    await p.waitForLoadState?.('domcontentloaded');
    resolve(p);
  })
);

// wait for the notification popup and fill it in
const approveNotificationPopup = await approvalPopup;
await approveNotificationPopup.bringToFront();
await approveNotificationPopup.waitForSelector('xpath///*[@id="approve"]/table/tbody/tr[1]/td[2]', { visible: true });
await runFile(browser, approveNotificationPopup, '041.SubmitNotificationApproval.json');


if (stepPause) {
  await waitForEnter('Step 04 complete. This is the last step. Press Enter to finish.');
}

rl.close();
await browser.close();


