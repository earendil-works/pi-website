#!/usr/bin/env node
import http from "node:http";
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import path from "node:path";

const port = Number(process.env.PORT || 8787);
const countsPath = path.resolve(process.env.COUNTS_PATH || "data/install-counts.json");
const flushIntervalMs = Number(process.env.FLUSH_INTERVAL_MS || 30000);
const proxyTarget = process.env.DEV_PROXY_TARGET;

let counts = {};
let dirty = false;
let flushing = false;

try {
	counts = JSON.parse(await readFile(countsPath, "utf8"));
} catch {}

function json(res, status, body) {
	res.writeHead(status, {
		"content-type": "application/json; charset=utf-8",
		"cache-control": "no-store",
		"access-control-allow-origin": "*",
	});
	res.end(JSON.stringify(body));
}

async function flush() {
	if (!dirty || flushing) return;
	flushing = true;
	try {
		dirty = false;
		await mkdir(path.dirname(countsPath), { recursive: true });
		await writeFile(`${countsPath}.tmp`, `${JSON.stringify(counts, null, 2)}\n`, "utf8");
		await rename(`${countsPath}.tmp`, countsPath);
	} catch {
		dirty = true;
	} finally {
		flushing = false;
		if (dirty) void flush();
	}
}

const timer = setInterval(() => {
	void flush();
}, flushIntervalMs);
timer.unref?.();

const server = http.createServer(async (req, res) => {
	const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);

	if (req.method === "GET" && url.pathname === "/install") {
		const version = url.searchParams.get("version");
		if (!version || !/^\d+\.\d+\.\d+$/.test(version)) {
			json(res, 400, { error: "invalid version" });
			return;
		}
		counts[version] = (counts[version] || 0) + 1;
		dirty = true;
		res.writeHead(204, {
			"cache-control": "no-store",
			"access-control-allow-origin": "*",
		});
		res.end();
		return;
	}

	if (req.method === "GET" && url.pathname === "/install-counts") {
		json(res, 200, counts);
		return;
	}

	if (req.method === "GET" && url.pathname === "/healthz") {
		json(res, 200, { ok: true });
		return;
	}

	if (!proxyTarget) {
		res.writeHead(404);
		res.end("not found");
		return;
	}

	try {
		const upstream = await fetch(new URL(req.url || "/", proxyTarget), {
			method: req.method,
			headers: req.headers,
			body: req.method === "GET" || req.method === "HEAD" ? undefined : req,
			duplex: "half",
		});
		res.writeHead(upstream.status, Object.fromEntries(upstream.headers.entries()));
		if (upstream.body) {
			for await (const chunk of upstream.body) {
				res.write(chunk);
			}
		}
		res.end();
	} catch {
		res.writeHead(502);
		res.end("bad gateway");
	}
});

async function shutdown() {
	clearInterval(timer);
	server.close();
	await flush();
	process.exit(0);
}

process.on("SIGINT", () => void shutdown());
process.on("SIGTERM", () => void shutdown());

server.listen(port, "0.0.0.0");
