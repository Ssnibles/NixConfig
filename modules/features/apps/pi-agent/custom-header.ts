/**
 * Custom Header Extension
 *
 * Replaces pi's built-in startup header with a pi mascot rendered in ASCII
 * art plus a short summary of the session (active model, working directory,
 * and common keybindings). Applied every time a new chat/session starts.
 *
 * Loaded via `--extension` by the pi-agent NixOS module.
 */

import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";

// --- PI MASCOT -----------------------------------------------------------------
// Renders the little pi agent character (a stylised "pi" with two eyes).
function getPiMascot(theme: Theme): string[] {
	const BLOCK = "█";
	const PUPIL = "▌";

	const piBlue = (text: string) => theme.fg("accent", text);
	const eye = `${theme.fg("text", BLOCK)}${theme.fg("dim", PUPIL)}`;

	return [
		"",
		`     ${eye}  ${eye}`,
		`  ${piBlue(BLOCK.repeat(14))}`,
		`     ${piBlue(BLOCK.repeat(2))}    ${piBlue(BLOCK.repeat(2))}`,
		`     ${piBlue(BLOCK.repeat(2))}    ${piBlue(BLOCK.repeat(2))}`,
		`     ${piBlue(BLOCK.repeat(2))}    ${piBlue(BLOCK.repeat(2))}`,
		"",
	];
}

// Shorten an absolute path so it fits nicely in a terminal header.
function shortenPath(path: string, max = 48): string {
	const home = process.env.HOME;
	let pretty = home && path.startsWith(home) ? `~${path.slice(home.length)}` : path;
	if (pretty.length > max) {
		pretty = `…${pretty.slice(pretty.length - max + 1)}`;
	}
	return pretty;
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		const cwd = shortenPath(ctx.cwd);

		ctx.ui.setHeader((_tui, theme) => {
			return {
				render(_width: number): string[] {
					const model = ctx.model;
					const modelLabel = model ? `${model.provider}/${model.id}` : "no model";
					const title =
						theme.bold(theme.fg("accent", "pi")) +
						theme.fg("muted", "  —  your AI coding companion");
					const details = [
						theme.fg("dim", `model  ${theme.fg("text", modelLabel)}`),
						theme.fg("dim", `cwd    ${theme.fg("text", cwd)}`),
					];
					const hints = theme.fg(
						"dim",
						`${theme.fg("text", "/")} commands  ·  ${theme.fg("text", "!")} bash  ·  ${theme.fg("text", "ctrl+c")} interrupt`,
					);

					return [
						...getPiMascot(theme),
						`  ${title}`,
						...details.map((line) => `  ${line}`),
						"",
						`  ${hints}`,
					];
				},
				invalidate() {},
			};
		});
	});

	// Restore pi's built-in header (handy when you want the full keybinding help).
	pi.registerCommand("builtin-header", {
		description: "Restore pi's built-in startup header",
		handler: async (_args, ctx) => {
			ctx.ui.setHeader(undefined);
			ctx.ui.notify("Built-in header restored", "info");
		},
	});
}
