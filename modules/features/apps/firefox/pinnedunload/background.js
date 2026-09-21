browser.runtime.onStartup.addListener(unloadPinnedTabs);

async function unloadPinnedTabs() {
  try {
    const tabs = await browser.tabs.query({});
    const ids = tabs
      .filter((t) => t.pinned && !t.discarded && !t.active)
      .map((t) => t.id)
      .filter((id) => id != null);
    if (ids.length) {
      await browser.tabs.discard(ids);
    }
  } catch (err) {
    console.warn("pinned-unload: failed to discard pinned tabs:", err);
  }
}