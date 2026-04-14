import { createRunner, PuppeteerRunnerExtension } from '@puppeteer/replay';
import puppeteer from 'puppeteer';
import fs from 'fs';

const browser = await puppeteer.launch({ headless: false });
const page = await browser.newPage();

const files = ['010.CreatePatientSwift_fake11aa.json', '014.AddMorbidityReport.json'];

for (const file of files) {
  console.log(`Running ${file}...`);
  const recording = JSON.parse(fs.readFileSync(file, 'utf8'));
  const runner = await createRunner(recording, new PuppeteerRunnerExtension(browser, page));
  await runner.run();
}

await browser.close();
