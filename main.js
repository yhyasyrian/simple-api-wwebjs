const express = require("express");
const {Client, LocalAuth} = require("whatsapp-web.js");
const qr2 = require("qrcode");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

// Note: Chromium crash reporting (crashpad) is problematic in some Docker images.
// We explicitly disable crashpad via Puppeteer args below to avoid startup failures.

function resolveChromeExecutablePath() {
	// Prefer explicit env var if it exists on disk, otherwise fall back to common paths.
	const candidates = [
		process.env.PUPPETEER_EXECUTABLE_PATH,
		"/usr/bin/google-chrome-stable",
		"/usr/bin/google-chrome",
		"/usr/bin/chromium",
		"/usr/bin/chromium-browser",
	].filter(Boolean);
	for (const p of candidates) {
		try {
			if (fs.existsSync(p)) return p;
		} catch (_) {
			// ignore
		}
	}
	// Last resort: return the env var even if it doesn't exist, so the error is explicit.
	return process.env.PUPPETEER_EXECUTABLE_PATH || "/usr/bin/chromium";
}

const app = express();
app.use(express.json());
app.use(express.urlencoded({extended: true}));
app.set("view engine", "ejs");
app.set("views", "pages");

let session = null;
let tokenQr = null;
let restartTimer = null;
let restartAttempts = 0;

function buildClient() {
	return new Client({
	authStrategy: new LocalAuth({
		dataPath: "session",
		clientId: "primary",
	}),
	puppeteer:{
		executablePath: resolveChromeExecutablePath(),
		// Prefer modern headless explicitly; in some environments it's more stable than boolean `true`.
		headless: "new",
		args:[
			"--no-sandbox",
			"--disable-setuid-sandbox",
			"--disable-dev-shm-usage",
			"--disable-gpu",
			"--no-zygote",
			"--user-data-dir=/tmp/chrome-user-data-primary",
			"--disable-extensions",
			"--disable-background-networking",
			"--disable-features=Translate,BackForwardCache",
		]
	}
	});
}

function scheduleRestart(reason) {
	if (restartTimer) return;
	restartAttempts += 1;
	const delayMs = Math.min(60000, 3000 * restartAttempts);
	console.error("WhatsApp client will restart in", delayMs, "ms بسبب:", reason?.message || reason);
	restartTimer = setTimeout(async () => {
		restartTimer = null;
		try {
			if (session) await session.destroy();
		} catch (_) {}
		startClient();
	}, delayMs);
}

function wireClientEvents(client) {
	client.on("qr", (qr) => {
		tokenQr = qr;
		console.log("qr", qr);
	});
	client.on("ready", () => {
		restartAttempts = 0;
		tokenQr = false;
		console.log("Login successful");
	});
	client.on("auth_failure", (msg) => {
		console.error("Auth failure:", msg);
		scheduleRestart(new Error("auth_failure"));
	});
	client.on("disconnected", (reason) => {
		console.error("Disconnected:", reason);
		scheduleRestart(new Error(`disconnected:${reason}`));
	});
}

function startClient() {
	try {
		session = buildClient();
		wireClientEvents(session);
		session.initialize();
	} catch (err) {
		scheduleRestart(err);
	}
}

// Prevent container crash loops on Puppeteer/Chrome transient failures.
process.on("unhandledRejection", (reason) => {
	console.error("Unhandled promise rejection:", reason);
	scheduleRestart(reason);
});
process.on("uncaughtException", (err) => {
	console.error("Uncaught exception:", err);
	scheduleRestart(err);
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
startClient();
const port = Number(process.env.PORT || 3000);
app.listen(port, () => {
	console.log(`Server is running on port ${port}`);
});
