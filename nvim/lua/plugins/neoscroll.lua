-- ============================================================================
-- NEOSCROLL (smooth scrolling)
-- Animates <C-u>/<C-d> and friends so large jumps are easier to track
-- visually. easing = "quadratic" gives a natural deceleration curve.
-- ============================================================================

require("neoscroll").setup({
	mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
	easing = "quadratic",
	-- Hide the cursor while scrolling to reduce visual noise.
	hide_cursor = true,
	-- Respect scrolloff so the cursor doesn't get too close to the edges.
	respect_scrolloff = true,
})
