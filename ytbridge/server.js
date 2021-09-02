import express from "express";
import ytdl from "ytdl-core";
import ffmpeg from "fluent-ffmpeg";

console.log("bah ouais frère");

const app = express();
const port = 3000;

app.get("/", (req, res) => {
  res.send("Hello World!");
});

app.get("/:video_id.:format", async (req, res) => {
  try {
    const infos = await ytdl.getInfo(`https://youtu.be/${req.params.video_id}`);

    if (req.params.format == "mp3") {
      console.log("streaming mp3");
      res.writeHead(200, {
        "Content-Type": "audio/mp3",
      });

      ffmpeg()
        .on("end", function () {
          console.log("file has been converted succesfully");
        })
        .on("progress", function (progress) {
          console.log("Processing: ", progress);
        })
        .on("error", function (err) {
          console.log("an error happened: " + err.message);
        })
        .input(
          ytdl.downloadFromInfo(infos, {
            filter: "audioonly",
            quality: "highestaudio",
          })
        )
        .format("mp3")
        .audioBitrate("192k")
        .audioChannels(2)
        .audioCodec("libmp3lame")
        .pipe(res, { end: true });
    } else {
      console.log("returning json data");
      res.send(infos);
    }
  } catch (err) {
    if (err.message.indexOf("TypeError: Video id")) {
      res.status(400).send(err.message);
      return;
    }
    throw err;
  }
});

app.listen(port, "0.0.0.0", () => {
  console.log(`Example app listening at http://localhost:${port}`);
});
