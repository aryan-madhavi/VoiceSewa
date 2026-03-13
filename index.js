const express = require('express');
const multer = require('multer');
const ffmpeg = require('fluent-ffmpeg');
const fs = require('fs');

const app = express();
const upload = multer({ dest: '/tmp' });

app.post('/convert', upload.single('file'), (req, res) => {
  const input = req.file.path;
  const output = `${input}-out.wav`;

  ffmpeg(input)
    .audioFrequency(8000)
    .audioChannels(1)
    .audioCodec('pcm_mulaw')
    .format('wav')
    .on('end', () => {
      res.download(output, () => {
        fs.unlinkSync(input);
        fs.unlinkSync(output);
      });
    })
    .on('error', (err) => {
      res.status(500).send(err.message);
    })
    .save(output);
});

app.listen(process.env.PORT || 3000);
