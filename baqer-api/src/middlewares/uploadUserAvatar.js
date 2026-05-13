const path = require('path');
const fs = require('fs');
const multer = require('multer');
const sharp = require('sharp');

const UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads', 'users');
const MAX_SIZE_BYTES = 300 * 1024; // 300 KB for avatar
const MAX_INPUT_SIZE = 5 * 1024 * 1024; // 5 MB before compression

const ALLOWED_MIMES = [
  'image/jpeg',
  'image/png',
  'image/webp',
];

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
  upload.single('avatar')(req, res, (err) => {
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
    let quality = 82;
    const width = 400;

    const pipeline = sharp(buffer)
      .resize(width, width, { fit: 'cover' })
      .webp({ quality });
    buffer = await pipeline.toBuffer();

    if (buffer.length > MAX_SIZE_BYTES) {
      buffer = await sharp(buffer).webp({ quality: 70 }).toBuffer();
    }
    fs.writeFileSync(outputPath, buffer);
    req.body.avatar = `/uploads/users/${filename}`;
    next();
  } catch (err) {
    next(err);
  }
}

function uploadUserAvatar(req, res, next) {
  const isMultipart = (req.headers['content-type'] || '').includes('multipart/form-data');
  if (!isMultipart) return next();
  runMulter(req, res, next);
}

module.exports = uploadUserAvatar;
