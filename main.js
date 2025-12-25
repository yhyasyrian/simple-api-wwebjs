const express = require("express");
const {Client, LocalAuth} = require("whatsapp-web.js");
const qr2 = require("qrcode");
require("dotenv").config();

const app = express();
app.use(express.json());
app.use(express.urlencoded({extended: true}));
app.set("view engine", "ejs");
app.set("views", "pages");
const session = new Client({
	authStrategy: new LocalAuth({
		dataPath: "session",
		clientId: "primary",
	}),
});
let tokenQr = null;
session.on("qr", (qr) => {
	tokenQr = qr;
	console.log("qr", qr);
});
session.on("ready", () => {
	tokenQr = false;
	console.log("Login successful");
});
app.get("/", (req, res) => {
	res.send("Hello World");
});
app.get("/whatsapp/login", async (req, res) => {
	if (tokenQr === null) return res.send("please try later");
	if (tokenQr === false) return res.send("Login successful");
	qr2.toDataURL(tokenQr, (err, src) => {
		if (err) return res.status(500).send("Error occured");
		return res.render("qr", {img: src});
	});
});

app.post("/whatsapp/sendmessage/", async (req, res) => {
	try {
		if (req.headers["x-password"] != process.env.WHATSAPP_API_PASSWORD) throw new Error("Invalid password");
		if (req.body.message === undefined) throw new Error("Message is required");
		if (req.body.phone === undefined) throw new Error("Number is required");
		await session.sendMessage(`${req.body.phone}@c.us`, req.body.message);
		res.json({
			ok: true,
			message: "Message sent",
		});
	} catch (error) {
		console.log("error", error);
		res.status(500).json({
			ok: false,
			message: "Message not sent",
		});
	}
});
session.initialize();
app.listen(process.env.PORT, () => {
	console.log(`Server is running on port ${process.env.PORT}`);
});
