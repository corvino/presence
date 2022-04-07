const express = require("express");
const ws = require("express-ws");

const app = express();
ws(app);

let num = 0;

function messageType(message) {
  let keys = Object.keys(message);
  if (1 === keys.length) {
    return keys[0];
  }
  return "";
}

function Connected(clientID) {
  return  { connected: { clientID: clientID } };
}

class Socket {
  constructor(ws, clientID) {
    this.ws = ws;
    this.clientID = clientID;

    ws.on("message", (msg) => { this.onMessage(msg) });
    ws.on("close", () => { });

    console.log(`client ${clientID} connected`);

    this.send(Connected(clientID));
  }

  onMessage(message)  {
    let envelope = JSON.parse(message);
    let type = messageType(envelope);
    console.log(`received ${type} message from ${this.clientID}`);
    switch (type) {
      case "ping":
        this.send({ pong: {} });
        break;
      default:
        console.log("unrecognized message", envelope);
    }
  }

  onClose() {
    console.log("close", this.clientID);
    // TODO: Check that this actually allows the object to be collected.
    this.ws = null;
  }

  send(message) {
    const buffer = Buffer.from(JSON.stringify(message), "utf-8");
    this.ws.send(buffer);
  }
}

app.ws("/connect", (ws, _) => {
  new Socket(ws, num++);
});

app.listen(3000);
