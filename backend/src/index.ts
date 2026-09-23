import jwt from "@tsndr/cloudflare-worker-jwt"

export interface Env {
	DB: D1Database;
	APNS_KEY_ID?: string;
	APNS_TEAM_ID?: string;
	APNS_TOPIC?: string;
	APNS_PRIVATE_KEY?: string;
}

interface ScheduledPing {
	id: number;
	device_token: string;
	scheduled_time: string;
	require_ack: number; // 0 or 1
	status: "PENDING" | "SENT";
	last_sent_at: number | null;
}

interface ScheduleRequestBody {
	device_token: string;
	scheduled_time: number; // unix timestamp in seconds
	require_ack: boolean;
}

interface AckRequestBody { // todo check ack struct later
	ping_id: number;
}

export default {
	// HTTP API
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		const url = new URL(request.url);

		// POST /schedule
		if (request.method == "POST" && url.pathname === "/schedule") { // invokes server once
			try {
				const body = (await request.json()) as ScheduleRequestBody;
				if (!body.device_token || !body.scheduled_time) {
					return new Response(JSON.stringify({ error: "Missing device_token or scheduled_time" }), { status: 400 });
				}

				if (body.scheduled_time <= Math.floor(Date.now() / 1000) + 60) { // check if scheduled time is at least 1 min in the future
					return new Response(JSON.stringify({ error: "Invalid scheduled_time" }), { status: 400 });
				}

				// calls db write once
				const info = await env.DB.prepare("INSERT INTO scheduled_pings (device_token, scheduled_time, require_ack) VALUES (?, ?, ?)").bind(body.device_token, body.scheduled_time, body.require_ack ? 1 : 0).run();

				return new Response(JSON.stringify({ success: true, ping_id: info.meta.lastrow_id }), { headers: { "Content-Type" : "application/json" } });
			} catch (err) {
				const message = err instanceof Error ? err.message : "Unknown Error";
				return new Response(JSON.stringify({ error: message }), { status: 400 });
			}
		}

		// POST /ack
		if (request.method == "POST" && url.pathname === "/ack") { // invokes server once
			try {
				const body = (await request.json()) as AckRequestBody;
				if (!body.ping_id) {
					return new Response(JSON.stringify({ error: "Missing ping_id" }), { status: 400 });
				}
				await env.DB.prepare("DELETE FROM scheduled_pings WHERE id = ?").bind(body.ping_id).run(); // calls db write once
				return new Response(JSON.stringify({ acknowledged: true }), { headers: { "Content-Type": "application/json" } });
			} catch (err) {
				const message = err instanceof Error ? err.message : "Unknown Error";
				return new Response(JSON.stringify({ error: message }), { status: 400 });
			}
		}
		return new Response("Not Found", { status: 404 });
	},

	// cron trigger (counts as one invokation on call, currently once per minute)
	async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
		const now = Math.floor(Date.now() / 1000);
		const oneMinuteAgo = now - 60;

		const { results } = await env.DB.prepare( // calls db read once
			"SELECT * FROM scheduled_pings WHERE (status = 'PENDING' AND scheduled_time <= ?) OR (status = 'SENT' AND require_ack = 1 AND last_sent_at <= ?)"
			).bind(now, oneMinuteAgo).all<ScheduledPing>();

		console.log(`[Cron run at ${new Date().toISOString()}] found ${results.length} jobs to process`);

		for (const job of results) { // one invokation call per row?
			let success = false;

			if (env.APNS_PRIVATE_KEY && env.APNS_KEY_ID && APNS_TEAM_ID && APNS_TOPIC) {
				success = await sendVisiblePush(env, job);
			} else {
				success = await mockSendVisiblePush(job);
			}

			if (success) { // calls db write once per success
				if (job.require_ack === 1) {
					await env.DB.prepare("UPDATE scheduled_pings SET status = 'SENT', last_sent_at = ? WHERE id = ?").bind(now, job.id).run();
				} else {
					await env.DB.prepare("DELETE FROM scheduled_pings WHERE id = ?").bind(job.id).run();
				}
			}
		}
	}
};

// apn visible push sender
async function sendVisiblePush(env: Env, job: ScheduledPing): Promise<boolean> {
	try {
		const token = await jwt.sign({ iss: env.APNS_TEAM_ID, iat: Math.floor(Date.now() / 1000) }, env.APNS_PRIVATE_KEY!, { "algorithm": "ES256", header: { kid: env.APNS_KEY_ID! } });
		const payload = { aps: { 
			alert: { title: "server cronjob ping", body: "you should not be able to see this lol" }, 
			sound: "default", 
			"mutable-content": 1 
		}, ping_id: job.id };

		const apnHost = "https://api.push.apple.com"; // or api.sandbox.push.apple.com for test runs
		const response = await fetch(`${apnHost}/3/device/${job.device_token}`, {
			method: "POST",
			headers: {
				authorization: `bearer ${token}`,
				"apns-topic": env.APNS_TOPIC!,
				"apns-push-type": "alert",
				"apns-priority": 10,
				"content-type": "application/json"
			}, body: JSON.stringify(payload)
		});

		return response.ok;
	} catch (error) {
		console.log(`APNs push failed for ping ${job.id}:`, error);
		return false;
	}
}

async function mockSendVisiblePush(job: ScheduledPing): Promise<boolean> {
	console.log(`[MOCK PUSH] Triggered for Ping ID: ${job.id} -> Token: ${job.device_token}`);
	return true;
}