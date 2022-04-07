const express = require("express");
const ws = require("express-ws");

const app = express();
ws(app);

let num = 0;

app.ws("/connect", (ws, _) => {
  const wsid = num++;

  ws.on("message", (msg) => {
    console.log(String(msg), wsid);
    ws.send(`pong ${wsid}`);
  });
  ws.on("close", () => {
    console.log("close", wsid);
  });
  console.log("socket", wsid);
});

app.listen(3000);
