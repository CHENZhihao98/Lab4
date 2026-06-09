const express = require("express");
const app = express();

app.get("/health", (req, res) => {
  res.json({ status: "ok", version: "1.0.0" });
});

app.get("/subscribers", (req, res) => {
  res.json([
    { id: 1, name: "Jean Dupont", email: "jean.dupont@example.com" },
    { id: 2, name: "Marie Martin", email: "marie.martin@example.com" },
  ]);
});

app.listen(3000, () => console.log("API démarrée sur :3000"));
