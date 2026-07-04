const dgram = require('node:dgram');
const { performance } = require('node:perf_hooks');

const servers = [
	'ntp3.orange.pl',
	'ntp2.tp.pl',
	'ntp2.orange.pl',
	'ntp.task.gda.pl',
	'puck.cbk.poznan.pl',
	'ntp.certum.pl',
	'ntp1.orange.pl',
	'ntp1.tp.pl',
	'ntp.nask.pl',
	'ntp.itl.waw.pl',
	'ntp.coi.pw.edu.pl',
	'ntp.icm.edu.pl',
	'ntp2.icm.edu.pl',
	'tempus2.gum.gov.pl',
	'ntp1.icm.edu.pl',
	'ntp.oa.uj.edu.pl',
	'tempus1.gum.gov.pl',
	'time.umk.pl',
];

const NTP_PORT = 123;
const NTP_EPOCH_OFFSET_SECONDS = 2_208_988_800;
const TIMEOUT_MS = 2000;
const TRIES = 7;
const DELAY_MS = 350;
const MIN_REPLIES_FOR_PREFERRED = 4;

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const nowMs = () => performance.timeOrigin + performance.now();

const writeNtpTimestamp = (packet, offset, unixMs) => {
	const seconds = Math.floor(unixMs / 1000) + NTP_EPOCH_OFFSET_SECONDS;
	const fraction = Math.floor(((unixMs % 1000) / 1000) * 0x1_0000_0000);

	packet.writeUInt32BE(seconds >>> 0, offset);
	packet.writeUInt32BE(fraction >>> 0, offset + 4);
};

const readNtpTimestamp = (packet, offset) => {
	const seconds = packet.readUInt32BE(offset);
	const fraction = packet.readUInt32BE(offset + 4);

	if (seconds === 0 && fraction === 0) return null;

	return ((seconds - NTP_EPOCH_OFFSET_SECONDS) * 1000) + ((fraction / 0x1_0000_0000) * 1000);
};

const createNtpPacket = transmitTimeMs => {
	const packet = Buffer.alloc(48);
	packet[0] = 0x23;
	writeNtpTimestamp(packet, 40, transmitTimeMs);
	return packet;
};

const parseNtpResponse = (server, requestPacket, responsePacket, sentAtMs, receivedAtMs) => {
	if (responsePacket.length < 48) {
		return { ok: false, server, error: 'invalid response length' };
	}

	const leapIndicator = responsePacket[0] >> 6;
	const version = (responsePacket[0] >> 3) & 0b111;
	const mode = responsePacket[0] & 0b111;
	const stratum = responsePacket[1];
	const rootDelayMs = responsePacket.readInt32BE(4) / 65.536;
	const rootDispersionMs = responsePacket.readUInt32BE(8) / 65.536;
	const originateMatches = responsePacket.subarray(24, 32).equals(requestPacket.subarray(40, 48));
	const receiveTimeMs = readNtpTimestamp(responsePacket, 32);
	const transmitTimeMs = readNtpTimestamp(responsePacket, 40);

	if (leapIndicator === 3) {
		return { ok: false, server, error: 'server clock is unsynchronized' };
	}

	if (mode !== 4) {
		return { ok: false, server, error: `unexpected NTP mode ${mode}` };
	}

	if (version < 3 || version > 4) {
		return { ok: false, server, error: `unsupported NTP version ${version}` };
	}

	if (stratum < 1 || stratum > 15) {
		return { ok: false, server, error: `invalid stratum ${stratum}` };
	}

	if (!originateMatches) {
		return { ok: false, server, error: 'originate timestamp mismatch' };
	}

	if (receiveTimeMs == null || transmitTimeMs == null) {
		return { ok: false, server, error: 'missing server timestamps' };
	}

	const delayMs = Math.max(0, (receivedAtMs - sentAtMs) - (transmitTimeMs - receiveTimeMs));
	const offsetMs = ((receiveTimeMs - sentAtMs) + (transmitTimeMs - receivedAtMs)) / 2;

	return {
		ok: true,
		server,
		delayMs,
		offsetMs,
		rootDelayMs,
		rootDispersionMs,
		stratum,
		version,
	};
};

const queryNtp = server =>
	new Promise(resolve => {
		const socket = dgram.createSocket('udp4');
		const sentAtMs = nowMs();
		const packet = createNtpPacket(sentAtMs);

		const state = {
			done: false,
			timer: null,
		};

		const finish = result => {
			if (state.done) return;

			state.done = true;
			clearTimeout(state.timer);
			socket.close();
			resolve(result);
		};

		state.timer = setTimeout(() => {
			finish({ ok: false, server, error: 'timeout' });
		}, TIMEOUT_MS);

		socket.once('message', msg => {
			finish(parseNtpResponse(server, packet, msg, sentAtMs, nowMs()));
		});

		socket.once('error', err => {
			finish({ ok: false, server, error: err.message });
		});

		socket.send(packet, NTP_PORT, server, err => {
			if (err) finish({ ok: false, server, error: err.message });
		});
	});

const sum = values => values.reduce((total, value) => total + value, 0);
const average = values => sum(values) / values.length;

const median = values => {
	const sorted = [...values].sort((a, b) => a - b);
	const middle = Math.floor(sorted.length / 2);

	if (sorted.length % 2 === 1) return sorted[middle];
	return (sorted[middle - 1] + sorted[middle]) / 2;
};

const standardDeviation = values => {
	if (values.length < 2) return 0;

	const avg = average(values);
	const variance = average(values.map(value => (value - avg) ** 2));
	return Math.sqrt(variance);
};

const testServer = async server => {
	const replies = [];
	const failures = [];

	for (let i = 0; i < TRIES; i++) {
		const result = await queryNtp(server);

		if (result.ok) {
			replies.push(result);
		} else {
			failures.push(result.error);
		}

		if (i < TRIES - 1) await sleep(DELAY_MS);
	}

	if (!replies.length) {
		return {
			ok: false,
			server,
			received: 0,
			error: failures.at(-1) || 'no valid NTP replies',
		};
	}

	const delays = replies.map(({ delayMs }) => delayMs);
	const offsets = replies.map(({ offsetMs }) => offsetMs);
	const rootDistances = replies.map(reply => (reply.rootDelayMs / 2) + reply.rootDispersionMs);

	return {
		ok: true,
		server,
		received: replies.length,
		lost: TRIES - replies.length,
		stratum: Math.min(...replies.map(({ stratum }) => stratum)),
		delayMedian: median(delays),
		delayBest: Math.min(...delays),
		delayWorst: Math.max(...delays),
		offsetMedian: median(offsets),
		offsetJitter: standardDeviation(offsets),
		rootDistanceMedian: median(rootDistances),
	};
};

const compareServers = (a, b) =>
	(b.received - a.received) ||
    (a.rootDistanceMedian - b.rootDistanceMedian) ||
    (a.offsetJitter - b.offsetJitter) ||
    (a.delayMedian - b.delayMedian) ||
    (a.stratum - b.stratum) ||
    (Math.abs(a.offsetMedian) - Math.abs(b.offsetMedian));

const formatMs = value => `${value.toFixed(2)}ms`;
const formatSignedMs = value => `${value >= 0 ? '+' : ''}${formatMs(value)}`;

const printResult = result => {
	if (!result.ok) {
		console.log(`FAIL ${result.error}`);
		return;
	}

	console.log(
		`OK replies=${result.received}/${TRIES} delay=${formatMs(result.delayMedian)} offset=${formatSignedMs(result.offsetMedian)} jitter=${formatMs(result.offsetJitter)} stratum=${result.stratum}`
	);
};

const printRanking = working => {
	console.log('\n=== Ranking by NTP quality ===');

	working.forEach((server, index) => {
		console.log(
			`${String(index + 1).padStart(2, ' ')}. ${server.server.padEnd(24)} replies=${server.received}/${TRIES} stratum=${server.stratum} delay=${formatMs(server.delayMedian)} best=${formatMs(server.delayBest)} worst=${formatMs(server.delayWorst)} offset=${formatSignedMs(server.offsetMedian)} jitter=${formatMs(server.offsetJitter)} rootdist=${formatMs(server.rootDistanceMedian)}`
		);
	});
};

const printChronyConfig = working => {
	const preferred = working.filter(({ received }) => received >= MIN_REPLIES_FOR_PREFERRED);

	if (!preferred.length) {
		console.log('\nNo NTP server reached the minimum reliability threshold.');
		process.exitCode = 1;
		return;
	}

	console.log('\nBest server:');
	console.log(`server ${preferred[0].server} iburst`);

	console.log('\nSuggested chrony config (/etc/chrony/chrony.conf):');

	preferred.slice(0, 3).forEach(({ server }, index) => {
		console.log(`server ${server} iburst${index === 0 ? ' prefer' : ''}`);
	});
};

const main = async () => {
	console.log(`Testing ${servers.length} NTP servers...`);
	console.log(`Tries per server: ${TRIES}`);
	console.log(`Minimum replies for recommendation: ${MIN_REPLIES_FOR_PREFERRED}/${TRIES}\n`);

	const results = [];

	for (const server of servers) {
		process.stdout.write(`Testing ${server}... `);

		const result = await testServer(server);
		results.push(result);
		printResult(result);
	}

	const working = results
		.filter(({ ok }) => ok)
		.sort(compareServers);

	printRanking(working);
	printChronyConfig(working);
};

main().catch(err => {
	console.error(err);
	process.exit(1);
});