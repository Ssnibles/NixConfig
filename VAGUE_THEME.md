# =============================================================================
# Vague Theme Color Palette Reference
# =============================================================================
# This file documents the official vague theme color palette used consistently
# across all UI components in this NixOS configuration.
#
# Components using this palette:
#   - Neovim (nvim/lua/lib/highlights.lua)
#   - Waybar (modules/home/desktop/waybar.nix)
#   - SwayNC (modules/home/desktop/swaync.nix)
#   - Hyprlock (modules/home/desktop/hyprlock.nix)
#   - Vicinae (modules/home/desktop/hyprland.nix)
#   - Tmux (modules/home/shell/tmux.nix)
#   - Fish/Ghostty/Foot (modules/home/shell/fish.nix)
# =============================================================================

## Core Colors

### Background
- `bg`:        #141415  - Main background (darkest)
- `bg-raised`: #1c1c24  - Raised surfaces (cards, panels, popups)
- `bg-subtle`: #252530  - Subtle backgrounds (hover states, selected items)
- `border`:    #252530  - Borders and dividers

### Foreground
- `fg`:      #cdcdcd  - Primary text
- `fg-mid`:  #878787  - Secondary text
- `fg-dim`:  #606079  - Tertiary text, hints, placeholders

## Accent Colors

### Primary
- `accent`: #6e94b2  - Primary accent (links, focus, interactive elements)
- `teal`:   #b4d4cf  - Secondary accent (complements blue)
- `purple`: #bb9dbd  - Tertiary accent (media, special highlights)

### Semantic
- `green`:  #7fa563  - Success, additions, positive states
- `yellow`: #f3be7c  - Warnings, attention
- `red`:    #d8647e  - Errors, deletions, critical states
- `orange`: #e8b589  - Special highlights, modifications

## Usage Guidelines

### Backgrounds
- Use `bg` for main window/app backgrounds
- Use `bg-raised` for floating windows, panels, cards
- Use `bg-subtle` for hover states, active items, selected rows
- Use `border` for all dividers and borders

### Text
- Use `fg` for primary content
- Use `fg-mid` for secondary labels, descriptions
- Use `fg-dim` for hints, placeholders, disabled text

### Accents
- Use `accent` (blue) for interactive elements, links, primary actions
- Use `teal` for complementary highlights, secondary accents
- Use `purple` for media-related elements (music, video)
- Use `green` for success states, additions, confirmations
- Use `yellow` for warnings, important notices
- Use `red` for errors, deletions, critical actions
- Use `orange` for special highlights, modifications

## Implementation

### Neovim (Lua)
```lua
local colors = {
  bg = "#141415",
  bg_raised = "#1c1c24",
  -- ... etc
}
vim.api.nvim_set_hl(0, "GroupName", { fg = colors.accent, bg = colors.bg })
```

### Waybar/SwayNC/Hyprlock (CSS)
```css
@define-color bg          #141415;
@define-color bg-raised   #1c1c24;
/* ... etc */
.element { color: @accent; background: @bg; }
```

### Tmux (Nix let-in)
```nix
let
  bg = "#141415";
  accent = "#6e94b2";
  # ... etc
in
{
  extraConfig = ''
    set -g status-style "fg=${fg},bg=${bg}"
  '';
}
```

### Vicinae (JSON)
```json
{
  "colors": {
    "core": {
      "background": "#141415",
      "accent": "#6e94b2"
    }
  }
}
```

## Visual Hierarchy

### Emphasis Levels
1. **Critical**: `red` on `bg` - Errors, destructive actions
2. **High**: `accent` on `bg` - Primary actions, focused elements
3. **Medium**: `fg` on `bg` - Main content
4. **Low**: `fg-mid` on `bg` - Secondary content
5. **Subtle**: `fg-dim` on `bg` - Hints, placeholders

### State Representation
- **Normal**: `fg` on `bg`
- **Hover**: `fg` on `bg-subtle`
- **Active/Selected**: `accent` on `bg-subtle`
- **Disabled**: `fg-dim` on `bg` with reduced opacity
- **Success**: `green` indicator/border
- **Warning**: `yellow` indicator/border
- **Error**: `red` indicator/border

## Animations & Transitions

All components should use smooth, consistent transitions:
- Duration: 200ms for most interactions, 300ms for larger movements
- Easing: `cubic-bezier(0.4, 0, 0.2, 1)` or `ease` for simpler cases
- Properties to animate: `color`, `background`, `border-color`, `opacity`

## Border Radius

Consistent rounding for visual cohesion:
- Large containers: 8px (waybar, swaync control center, notifications)
- Medium elements: 6px (buttons, action buttons)
- Small elements: 4px (close buttons, small controls)

## Spacing

Consistent padding and margins:
- Large: 12-16px (container padding)
- Medium: 8-10px (element padding)
- Small: 4-6px (compact elements)
- Tiny: 2px (tight spacing)

## Typography

Font family: "JetBrains Mono", monospace
Font sizes:
- XL: 72px (hyprlock clock)
- Large: 20px (hyprlock date)
- Medium: 13-14px (titles, primary text)
- Normal: 11-12px (body text, descriptions)
- Small: 10px (labels, hints)

Font weights:
- 600: Bold (titles, headings, emphasized text)
- 400: Normal (body text)

## Accessibility Notes

- Contrast ratio between `fg` and `bg` is ~9.5:1 (WCAG AAA compliant)
- Accent colors have sufficient contrast for interactive elements
- Error and warning colors are distinguishable for colorblind users
- Icons and text are used together for critical information
