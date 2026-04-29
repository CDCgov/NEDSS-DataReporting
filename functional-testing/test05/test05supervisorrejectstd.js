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
await runFile(browser, page, '050.InvestigateSyphilisAssignFieldFollowup.json');
if (stepPause) {
  await waitForEnter('Step 05 complete. Press Enter to continue.');
}


//
//
// step 06: patient interview added
await runFile(browser, page, '060.InterviewInformationSyphilis.json');
await runFile(browser, page, '064.AddInterviewSyphilis.json');
const interviewPage = await waitForPopup();
await interviewPage.bringToFront();
await runFile(browser, interviewPage, '066.AddInterviewPopupSyphilis.json');
if (stepPause) {
  await waitForEnter('Step 06 complete. Press Enter to continue.');
}

//
//
// step 07: contact record added
await runFile(browser, page, '070.AddContactSyphilis.json');
const contactPage = await waitForPopup();
await contactPage.bringToFront();
await runFile(browser, contactPage, '072.AddContactPopup.json');
if (stepPause) {
  await waitForEnter('Step 07 complete. Press Enter to continue.');
}

//
//
// step 08: contact disposition
await runFile(browser, page, '080.ChangeContactInvestigationDisposition.json');
await runFile(browser, page, '082.SupervisorApprovesContactDisposition.json');
if (stepPause) {
  await waitForEnter('Step 08 complete. Press Enter to continue.');
}

//
//
// step 09: close investigation
await runFile(browser, page, '090.CloseInvestigationSyphilis.json');
if (stepPause) {
  await waitForEnter('Step 09 complete. Press Enter to continue.');
}

//
//
// step 10: supervisor rejects investigation close
await runFile(browser, page, '100.SupervisorRejectsCloseInvestigation.json');
if (stepPause) {
  await waitForEnter('Step 10 complete. Press Enter to continue.');
}

//
//
// step 11: update investigation and close again
await runFile(browser, page, '110.UpdateInvestigationAndCloseSyphilis.json');
await runFile(browser, page, '112.CreateNotificationSyphilis.json');
if (stepPause) {
  await waitForEnter('Step 11 complete. Press Enter to continue.');
}

//
//
// step 12: supervisor approves investigation close
await runFile(browser, page, '120.SupervisorApprove.json');
if (stepPause) {
  await waitForEnter('Step 12 complete. Press Enter to continue.');
}

rl.close();
await browser.close();


