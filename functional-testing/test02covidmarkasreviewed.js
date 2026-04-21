import { createRunner, PuppeteerRunnerExtension } from '@puppeteer/replay';
import puppeteer from 'puppeteer';
import fs from 'fs';
import readline from 'readline';

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
await runFile(browser, page, '010.CreatePatientSwift_fake66ff.json');
await runFile(browser, page, '012.AddLabReportManualCovid.json');

if (stepPause) {
  await waitForEnter('Step 01 complete. Press Enter to continue.');
}

//
//
// step 02: mark the case as reviewed
// QUEUE: only run this test to collect data if there is nothing
// other than this one Lab Report in the Documents Requiring Review Queue.
await runFile(browser, page, '020.MarkAsReviewedCovid.json');

if (stepPause) {
  await waitForEnter('Step 02 complete. Press Enter to finish.');
}

rl.close();
await browser.close();

