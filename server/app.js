const express = require("express");
const ws = require("express-ws");

const app = express();
ws(app);

let num = 0;

let users = {};

function messageType(message) {
  let keys = Object.keys(message);
  if (1 === keys.length) {
    return keys[0];
  }
  return "";
}

function Connected(clientID) {
  return  {
    connected: {
      clientID: clientID
    }
  };
}

function UserCreated(name) {
  return {
    userCreated: {
      name: name
    }
  }
}

function findNewName() {
  const keys = Object.keys(users);
  let i = 1;
  do {
    const name = `New User ${i}`;
    if (!(name in users)) {
      return name;
    }
  } while (i++)
}

function createUser(socket) {
  const name = findNewName();
  users[name] = socket;
  socket.send(UserCreated(name))
  console.log(`created ${name}`);
  return name;
}

class Socket {
  constructor(ws, clientID) {
    this.ws = ws;
    this.clientID = clientID;

    ws.on("message", (msg) => { this.onMessage(msg) });
    ws.on("close", () => { this.onClose() });

    console.log(`client ${clientID} connected`);

    this.send(Connected(clientID));
  }

  onMessage(message)  {
    let envelope = JSON.parse(message);
    let type = messageType(envelope);
    console.log(`received ${type} message from ${this.clientID}`);

    switch (type) {
      case "createUser":
        this.name = createUser(this);
        this.send(UserCreated(this.name));
        break;
      case "ping":
        this.send({ pong: {} });
        break;
      default:
        console.log("unrecognized message", envelope);
    }
  }

  onClose() {
    console.log("close", this.clientID);
    if (null !== this.name) {
      delete users[this.name];
    }
    // TODO: Check that this actually allows the object to be collected.
    this.ws = null;
  }

  send(message) {
    const buffer = Buffer.from(JSON.stringify(message), "utf-8");
    this.ws.send(buffer);
  }
}

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

app.ws("/connect", async (ws, _) => {
//  await sleep(10000);
  new Socket(ws, num++);
});

app.listen(3000);
