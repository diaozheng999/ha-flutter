import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type RuntimeIdentityContext = Pick<ExtensionContext, "cwd" | "mode" | "model" | "sessionManager">;

export function buildRuntimeIdentity(ctx: RuntimeIdentityContext, observedAt = new Date()) {
	return {
		coding_agent: "pi",
		provider: ctx.model?.provider ?? "unavailable",
		model: ctx.model?.id ?? "unavailable",
		session_id: ctx.sessionManager.getSessionId(),
		mode: ctx.mode,
		working_directory: ctx.cwd,
		observed_at: observedAt.toISOString(),
	};
}

export default function runtimeContextExtension(pi: ExtensionAPI) {
	pi.on("before_agent_start", (event, ctx) => {
		const runtimeIdentity = JSON.stringify(buildRuntimeIdentity(ctx), null, 2);

		return {
			systemPrompt: `${event.systemPrompt}\n\n## Pi runtime identity\nThe Pi host supplied this authoritative JSON for the current turn:\n\n\`\`\`json\n${runtimeIdentity}\n\`\`\`\n\nUse these exact values when provenance is requested. Do not infer missing values or expose credentials.`,
		};
	});
}
