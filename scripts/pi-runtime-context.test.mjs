import assert from "node:assert/strict";
import test from "node:test";

import runtimeContextExtension, {
	buildRuntimeIdentity,
} from "../.pi/extensions/runtime-context.ts";

function makeContext(model) {
	return {
		cwd: "C:/workspace/ha-flutter",
		mode: "json",
		model,
		sessionManager: {
			getSessionId: () => "session-123",
		},
	};
}

test("buildRuntimeIdentity exposes only the reviewed host fields", () => {
	const identity = buildRuntimeIdentity(
		makeContext({ provider: "nvidia", id: "nvidia/nemotron-3-ultra-550b-a55b" }),
		new Date("2026-07-19T08:00:00.000Z"),
	);

	assert.deepEqual(identity, {
		coding_agent: "pi",
		provider: "nvidia",
		model: "nvidia/nemotron-3-ultra-550b-a55b",
		session_id: "session-123",
		mode: "json",
		working_directory: "C:/workspace/ha-flutter",
		observed_at: "2026-07-19T08:00:00.000Z",
	});
	assert.equal("apiKey" in identity, false);
	assert.equal("modelRegistry" in identity, false);
});

test("buildRuntimeIdentity uses unavailable without inferring a model", () => {
	const identity = buildRuntimeIdentity(makeContext(undefined), new Date("2026-07-19T08:00:00.000Z"));

	assert.equal(identity.provider, "unavailable");
	assert.equal(identity.model, "unavailable");
});

test("extension appends JSON identity during every before_agent_start", () => {
	let handler;
	runtimeContextExtension({
		on(event, registeredHandler) {
			assert.equal(event, "before_agent_start");
			handler = registeredHandler;
		},
	});

	assert.equal(typeof handler, "function");
	const result = handler(
		{ systemPrompt: "base prompt" },
		makeContext({ provider: "nvidia", id: "test-model" }),
	);

	assert.match(result.systemPrompt, /^base prompt\n\n## Pi runtime identity/);
	assert.match(result.systemPrompt, /"provider": "nvidia"/);
	assert.match(result.systemPrompt, /"model": "test-model"/);
	assert.match(result.systemPrompt, /"session_id": "session-123"/);
});
