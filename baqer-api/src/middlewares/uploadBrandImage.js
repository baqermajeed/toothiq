const path = require('path');
const fs = require('fs');
const multer = require('multer');
const sharp = require('sharp');

const UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads', 'brands');
const MAX_SIZE_BYTES = 300 * 1024;
const MAX_INPUT_SIZE = 5 * 1024 * 1024;

const ALLOWED_MIMES = ['image/jpeg', 'image/png', 'image/webp'];

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  if (ALLOWED_MIMES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('نوع الملف غير مدعوم. يُقبل الصور فقط (jpeg, png, webp)'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: MAX_INPUT_SIZE },
});

function runMulter(req, res, next) {
  upload.single('image')(req, res, (err) => {
    if (err) return next(err);
    if (!req.file) return next();
    compressAndSave(req, next);
  });
}

async function compressAndSave(req, next) {
  try {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
    const ext = '.webp';
    const filename = `${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`;
    const outputPath = path.join(UPLOAD_DIR, filename);

    let buffer = req.file.buffer;
    let quality = 80;
    let width = 400;

    while (buffer.length > MAX_SIZE_BYTES && (quality > 20 || width > 200)) {
      const pipeline = sharp(buffer)
        .resize(width, null, { withoutEnlargement: true })
        .webp({ quality });
      buffer = await pipeline.toBuffer();
      if (buffer.length > MAX_SIZE_BYTES) {
        if (quality > 20) quality -= 10;
        else if (width > 200) {
          width = Math.max(200, Math.floor(width * 0.85));
          quality = 80;
        }
      }
    }

    const finalBuffer =
      buffer.length > MAX_SIZE_BYTES
        ? await sharp(buffer).webp({ quality: 20 }).toBuffer()
        : buffer;
    fs.writeFileSync(outputPath, finalBuffer);
    req.body.image = `/uploads/brands/${filename}`;
    next();
  } catch (err) {
    next(err);
  }
}

function uploadBrandImage(req, res, next) {
  const isMultipart = (req.headers['content-type'] || '').includes('multipart/form-data');
  if (!isMultipart) return next();
  runMulter(req, res, next);
}

module.exports = uploadBrandImage;
