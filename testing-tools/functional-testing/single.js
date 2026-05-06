import { createRunner, PuppeteerRunnerExtension } from "@puppeteer/replay";
import puppeteer from "puppeteer";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function usage() {
    console.log("Usage: node single.js <replay-file.json>");
    console.log("Example: node single.js 014.AddMorbidityReport.json");
}

const replayArg = process.argv[2];
if (!replayArg) {
    usage();
    process.exit(1);
}

// Allow either:
// 1) path relative to current working dir
// 2) path relative to this script's folder
const candidates = [
    path.resolve(process.cwd(), replayArg),
    path.resolve(__dirname, replayArg),
];

const replayPath = candidates.find((p) => fs.existsSync(p));

if (!replayPath) {
    console.error(`Replay file not found: ${replayArg}`);
    console.error("Checked:");
    for (const c of candidates) console.error(`  - ${c}`);
    process.exit(1);
}

if (!replayPath.toLowerCase().endsWith(".json")) {
    console.error("Replay file must be a .json recording.");
    process.exit(1);
}

let browser;
try {
    console.log(`Running replay: ${replayPath}`);
    const recording = JSON.parse(fs.readFileSync(replayPath, "utf8"));

    browser = await puppeteer.launch({ headless: false });
    const page = await browser.newPage();

    const runner = await createRunner(
        recording,
        new PuppeteerRunnerExtension(browser, page, { timeout: 10000 }),
    );

    await runner.run();
    console.log("Replay completed successfully.");
} catch (err) {
    console.error("Replay failed.");
    console.error(err);
    process.exitCode = 1;
} finally {
    if (browser) {
        await browser.close();
    }
}
