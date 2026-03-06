/**
 * Resize screenshots for 13-inch iPad (App Store requirement)
 * Run: node scripts/resize-for-ipad.js
 *
 * iPad 13" portrait: 2048 x 2732 pixels
 * Output: screenshots-output/ipad-*.png
 */

const fs = require('fs');
const path = require('path');

const WIDTH = 2048;
const HEIGHT = 2732;

const inputDir = path.join(__dirname, '..', 'screenshots-input');
const outputDir = path.join(__dirname, '..', 'screenshots-output');

if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

const files = fs.readdirSync(inputDir)
  .filter((f) => /\.(png|jpg|jpeg)$/i.test(f))
  .sort();

if (files.length === 0) {
  console.log('No images in screenshots-input. Add screenshots and run again.');
  process.exit(1);
}

const sharp = require('sharp');

async function resize() {
  for (const file of files) {
    const inputPath = path.join(inputDir, file);
    const base = file.replace(/\.[^.]+$/, '');
    const outputPath = path.join(outputDir, `ipad-${base}.png`);
    await sharp(inputPath)
      .resize(WIDTH, HEIGHT, { fit: 'cover', position: 'center' })
      .toFile(outputPath);
    console.log(`  ${file} → ipad-${base}.png`);
  }
  console.log(`\nDone! ${files.length} iPad images (2048×2732) in screenshots-output/`);
  console.log('Upload to App Store Connect → 13-inch iPad display.');
}

resize().catch((err) => {
  console.error(err);
  process.exit(1);
});
