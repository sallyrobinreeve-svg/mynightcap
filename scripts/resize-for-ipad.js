/**
 * Resize one screenshot for 13-inch iPad (App Store requirement)
 * Run: node scripts/resize-for-ipad.js
 *
 * Uses the first image from screenshots-input, outputs to screenshots-output/ipad-13inch.png
 * iPad 13" portrait: 2048 x 2732
 */

const fs = require('fs');
const path = require('path');

const WIDTH = 2048;
const HEIGHT = 2732;

const inputDir = path.join(__dirname, '..', 'screenshots-input');
const outputDir = path.join(__dirname, '..', 'screenshots-output');
const outputPath = path.join(outputDir, 'ipad-13inch.png');

// Prefer screens that show app in use (not login). Apple rejects login-only screenshots.
const PREFERRED = ['04-feed', '06-profile', '05-new-entry', '3-prompts', '2-new-entry', '07-memories', '08-leaderboard'];
const allFiles = fs.readdirSync(inputDir).filter((f) => /\.(png|jpg|jpeg)$/i.test(f));
const preferred = PREFERRED.find((p) => allFiles.some((f) => f.startsWith(p)));
const firstFile = preferred ? allFiles.find((f) => f.startsWith(preferred)) : allFiles.sort()[0];

if (!firstFile) {
  console.log('No images in screenshots-input. Add one and run again.');
  process.exit(1);
}

const sharp = require('sharp');
const inputPath = path.join(inputDir, firstFile);

sharp(inputPath)
  .resize(WIDTH, HEIGHT, { fit: 'cover', position: 'center' })
  .toFile(outputPath)
  .then(() => console.log(`Created: ${outputPath}\nUpload to App Store Connect → iPad 13" display.`))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
