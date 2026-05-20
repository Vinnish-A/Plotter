(function () {
  const manifest = window.PLOTTER_ASSETS || { assets: [] };
  const assets = manifest.assets || [];
  const grid = document.getElementById("grid");
  const empty = document.getElementById("empty");
  const search = document.getElementById("search");
  const modeGroup = document.getElementById("modeGroup");
  const rebuiltOnly = document.getElementById("rebuiltOnly");
  const summary = document.getElementById("summary");
  const sourceDialog = document.getElementById("sourceDialog");
  const closeSource = document.getElementById("closeSource");
  const sourceTitle = document.getElementById("sourceTitle");
  const sourceMeta = document.getElementById("sourceMeta");
  const sourceImage = document.getElementById("sourceImage");
  const sourceKeywords = document.getElementById("sourceKeywords");
  const sourceGroupEditor = document.getElementById("sourceGroupEditor");
  const sourceGroupStatus = document.getElementById("sourceGroupStatus");
  const sourceData = document.getElementById("sourceData");
  const originalSourcePath = document.getElementById("originalSourcePath");
  const originalSourceCode = document.getElementById("originalSourceCode");
  const copyOriginalSource = document.getElementById("copyOriginalSource");
  const sourceCodePath = document.getElementById("sourceCodePath");
  const sourceCode = document.getElementById("sourceCode");
  const copyStandardEntry = document.getElementById("copyStandardEntry");

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;");
  }

  function asList(value) {
    return Array.isArray(value) ? value.filter(Boolean) : [];
  }

  function pills(values) {
    const list = asList(values);
    if (!list.length) return '<span class="muted">None declared</span>';
    return list.map((value) => `<span class="pill">${escapeHtml(value)}</span>`).join("");
  }

  function dataRow(label, value) {
    const content = Array.isArray(value) ? pills(value) : escapeHtml(value || "None declared");
    return `<dt>${escapeHtml(label)}</dt><dd>${content}</dd>`;
  }

  function uniqueValues(key) {
    return [...new Set(assets.map((asset) => asset[key]).filter(Boolean))].sort();
  }

  const modeOrder = new Map([
    ["low", 0],
    ["medium", 1],
    ["high", 2],
    ["custom", 3],
  ]);

  function compareMode(left, right) {
    const leftKey = String(left || "").toLowerCase();
    const rightKey = String(right || "").toLowerCase();
    const leftRank = modeOrder.has(leftKey) ? modeOrder.get(leftKey) : 99;
    const rightRank = modeOrder.has(rightKey) ? modeOrder.get(rightKey) : 99;
    if (leftRank !== rightRank) return leftRank - rightRank;
    return String(left).localeCompare(String(right));
  }

  const groupOptions = ["low", "medium", "high", "custom"];
  const modeValues = [...new Set([...groupOptions, ...uniqueValues("mode")])].sort(compareMode);
  const selectedModes = new Set(modeValues);
  let activeSourceAsset = null;

  function selectedAllModes() {
    return modeValues.length > 0 && selectedModes.size === modeValues.length;
  }

  function renderModeGroup() {
    const buttons = [
      `<button class="segment ${selectedAllModes() ? "active" : ""}" type="button" data-mode="__all" aria-pressed="${selectedAllModes()}">All</button>`,
      ...modeValues.map((value) => {
        const active = selectedModes.has(value);
        return `<button class="segment ${active ? "active" : ""}" type="button" data-mode="${escapeHtml(value)}" aria-pressed="${active}">${escapeHtml(value)}</button>`;
      }),
    ];
    modeGroup.innerHTML = buttons.join("");
  }

  function badge(asset) {
    if (asset.rebuilt_exists) {
      return '<span class="badge rebuilt">rebuilt</span>';
    }
    if (asset.preview_image) {
      return '<span class="badge source">source preview</span><span class="badge missing-rebuilt">no rebuilt</span>';
    }
    return '<span class="badge missing-rebuilt">no rebuilt</span>';
  }

  function renderCard(asset, index) {
    const grammar = asset.visual_grammar || {};
    const backend = grammar.backend || asset.render_runtime || "";
    const geometry = grammar.geometry || "";
    const keywords = (grammar.keywords || []).slice(0, 5).join(", ");
    const grammarLine = [backend, geometry, keywords].filter(Boolean).join(" · ");
    const image = asset.preview_image
      ? `<img loading="lazy" src="${encodeURI(asset.preview_image)}" alt="${escapeHtml(asset.title)}">`
      : '<span class="missing">No rebuilt image</span>';
    return `
      <article class="card">
        <button class="thumb" type="button" data-action="source" data-index="${index}" aria-label="View source for ${escapeHtml(asset.title)}">${image}</button>
        <div class="body">
          <div class="badges">
            ${badge(asset)}
            ${asset.mode ? `<span class="badge">${escapeHtml(asset.mode)}</span>` : ""}
            ${asset.build_status ? `<span class="badge">${escapeHtml(asset.build_status)}</span>` : ""}
          </div>
          <h2 class="title">${escapeHtml(asset.title)}</h2>
          <p class="meta">${escapeHtml(asset.case_dir)}</p>
          <p class="deps">${escapeHtml(grammarLine || "No visual grammar declared")}</p>
        </div>
      </article>
    `;
  }

  function codeUrl(sourceInfo) {
    if (!sourceInfo.url) return "";
    return new URL(sourceInfo.url, window.location.href).toString();
  }

  function sourceLabel(sourceInfo, fallback) {
    return sourceInfo.path || fallback;
  }

  function renderSourceGroupEditor(asset) {
    sourceGroupEditor.innerHTML = groupOptions
      .map((value) => {
        const active = asset.mode === value;
        return `<button class="segment ${active ? "active" : ""}" type="button" data-group="${escapeHtml(value)}" aria-pressed="${active}">${escapeHtml(value)}</button>`;
      })
      .join("");
  }

  function refreshSourceMeta(asset) {
    sourceMeta.textContent = [asset.case_dir, asset.mode, asset.build_status].filter(Boolean).join(" · ");
  }

  function setCopyButtonState(button, state) {
    if (!button) return;
    const labels = {
      idle: "Copy code",
      loading: "Loading source",
      copied: "Copied",
      failed: "Copy failed",
      unavailable: "No code to copy",
    };
    button.dataset.copyState = state;
    button.setAttribute("aria-label", labels[state] || labels.idle);
    button.title = labels[state] || labels.idle;
    button.classList.toggle("copied", state === "copied");
    button.classList.toggle("failed", state === "failed");
    button.disabled = state === "loading" || state === "unavailable";
  }

  function resetCopyButtons() {
    setCopyButtonState(copyOriginalSource, "loading");
    setCopyButtonState(copyStandardEntry, "loading");
  }

  function openSourceShell(asset) {
    const grammar = asset.visual_grammar || {};
    const data = asset.data_contract || {};
    const standardization = asset.standardization || {};
    const source = asset.source || {};
    const originalInfo = asset.original_source_code || {};
    const standardInfo = asset.standard_entry_code || {};
    const keywords = [
      ...(asList(grammar.keywords)),
      grammar.backend,
      grammar.geometry,
      ...(asList(grammar.visual_dependencies)),
    ].filter(Boolean);

    sourceTitle.textContent = asset.title || asset.case_dir;
    activeSourceAsset = asset;
    refreshSourceMeta(asset);
    sourceImage.src = asset.preview_image ? encodeURI(asset.preview_image) : "";
    sourceImage.alt = asset.title || asset.case_dir;
    sourceKeywords.innerHTML = pills([...new Set(keywords)]);
    renderSourceGroupEditor(asset);
    sourceGroupStatus.textContent = "";
    sourceData.innerHTML = [
      dataRow("Interface", data.interface || "single_csv"),
      dataRow("Main CSV", data.main_csv || "data_main.csv"),
      dataRow("Optional CSV", data.optional_csv || "data_optional.csv"),
      dataRow("Required Data", data.required_mappings || []),
      dataRow("Optional Data", data.optional_mappings || []),
      dataRow("Grammar Geometry", standardization.grammar_geometry || grammar.geometry || ""),
      dataRow("Raw Resources", data.declared_raw_resources || []),
      dataRow("Original Source", [source.root, source.original_path].filter(Boolean).join(" / ")),
    ].join("");

    originalSourcePath.textContent = sourceLabel(originalInfo, "No original plotting source declared.");
    originalSourceCode.textContent = "Loading source...";
    sourceCodePath.textContent = sourceLabel(standardInfo, "No standard entry source declared.");
    sourceCode.textContent = "Loading source...";
    resetCopyButtons();
    if (typeof sourceDialog.showModal === "function" && !sourceDialog.open) {
      sourceDialog.showModal();
    } else {
      sourceDialog.setAttribute("open", "");
    }
    document.body.classList.add("modal-open");
  }

  async function loadCodeBlock(sourceInfo, target, copyButton) {
    if (!sourceInfo.url) {
      target.textContent = "No source file is available for this section.";
      setCopyButtonState(copyButton, "unavailable");
    } else {
      try {
        const response = await fetch(codeUrl(sourceInfo), { cache: "no-store" });
        if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
        target.textContent = await response.text();
        setCopyButtonState(copyButton, target.textContent ? "idle" : "unavailable");
      } catch (error) {
        target.textContent = `Unable to load source: ${error.message}`;
        setCopyButtonState(copyButton, "unavailable");
      }
    }
  }

  function showSource(asset) {
    openSourceShell(asset);
    loadCodeBlock(asset.original_source_code || {}, originalSourceCode, copyOriginalSource);
    loadCodeBlock(asset.standard_entry_code || {}, sourceCode, copyStandardEntry);
  }

  async function writeClipboardText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return;
    }

    const buffer = document.createElement("textarea");
    buffer.value = text;
    buffer.setAttribute("readonly", "");
    buffer.style.position = "fixed";
    buffer.style.left = "-9999px";
    document.body.appendChild(buffer);
    buffer.select();
    try {
      if (!document.execCommand("copy")) {
        throw new Error("copy command rejected");
      }
    } finally {
      document.body.removeChild(buffer);
    }
  }

  async function copyCode(button) {
    const target = document.getElementById(button.dataset.copyTarget || "");
    const text = target ? target.textContent : "";
    if (!text) {
      setCopyButtonState(button, "unavailable");
      return;
    }

    try {
      await writeClipboardText(text);
      setCopyButtonState(button, "copied");
      window.setTimeout(() => {
        if (button.dataset.copyState === "copied") setCopyButtonState(button, "idle");
      }, 1200);
    } catch (error) {
      setCopyButtonState(button, "failed");
      window.setTimeout(() => {
        if (button.dataset.copyState === "failed") setCopyButtonState(button, "idle");
      }, 1800);
    }
  }

  async function updateAssetGroup(asset, targetMode) {
    if (!asset || asset.mode === targetMode) return;
    sourceGroupStatus.textContent = "Saving...";
    try {
      const response = await fetch("/api/assets/mode", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ case_dir: asset.case_dir, mode: targetMode }),
      });
      const payload = await response.json();
      if (!response.ok || !payload.ok) throw new Error(payload.error || `${response.status} ${response.statusText}`);
      asset.mode = payload.mode || targetMode;
      refreshSourceMeta(asset);
      renderSourceGroupEditor(asset);
      renderModeGroup();
      render();
      sourceGroupStatus.textContent = `Saved to ${asset.mode}.`;
    } catch (error) {
      sourceGroupStatus.textContent = `Save failed: ${error.message}`;
    }
  }

  function currentAssets() {
    const query = search.value.trim().toLowerCase();
    return assets.filter((asset) => {
      if (modeValues.length && !selectedAllModes() && !selectedModes.has(asset.mode)) return false;
      if (rebuiltOnly.checked && !asset.rebuilt_exists) return false;
      if (!query) return true;
      const grammar = asset.visual_grammar || {};
      return [
        asset.title,
        asset.case_dir,
        asset.id,
        asset.mode,
        asset.build_status,
        grammar.backend,
        grammar.geometry,
        ...(grammar.keywords || []),
      ]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(query));
    }).sort((left, right) => compareMode(left.mode, right.mode) || String(left.title || left.case_dir).localeCompare(String(right.title || right.case_dir)));
  }

  function render() {
    const visible = currentAssets();
    grid.innerHTML = visible.map(renderCard).join("");
    empty.hidden = visible.length !== 0;
    summary.textContent = `${visible.length} visible of ${assets.length} live assets; ${manifest.rebuilt_count || 0} rebuilt images available. Folded assets are excluded.`;
  }

  renderModeGroup();

  for (const control of [search, rebuiltOnly]) {
    control.addEventListener("input", render);
    control.addEventListener("change", render);
  }

  modeGroup.addEventListener("click", (event) => {
    const button = event.target.closest("[data-mode]");
    if (!button) return;
    const value = button.dataset.mode;
    if (value === "__all") {
      selectedModes.clear();
      modeValues.forEach((modeValue) => selectedModes.add(modeValue));
    } else if (selectedModes.has(value)) {
      selectedModes.delete(value);
    } else {
      selectedModes.add(value);
    }
    renderModeGroup();
    render();
  });

  sourceGroupEditor.addEventListener("click", (event) => {
    const button = event.target.closest("[data-group]");
    if (!button) return;
    updateAssetGroup(activeSourceAsset, button.dataset.group);
  });

  sourceDialog.addEventListener("click", (event) => {
    const button = event.target.closest("[data-copy-target]");
    if (!button) return;
    copyCode(button);
  });

  grid.addEventListener("click", (event) => {
    const trigger = event.target.closest('[data-action="source"]');
    if (!trigger) return;
    const index = Number(trigger.dataset.index);
    const asset = currentAssets()[index];
    if (asset) showSource(asset);
  });

  grid.addEventListener("keydown", (event) => {
    if (event.key !== "Enter" && event.key !== " ") return;
    const trigger = event.target.closest('[data-action="source"]');
    if (!trigger) return;
    event.preventDefault();
    const index = Number(trigger.dataset.index);
    const asset = currentAssets()[index];
    if (asset) showSource(asset);
  });

  function closeSourceDialog() {
    sourceDialog.close();
    document.body.classList.remove("modal-open");
  }

  closeSource.addEventListener("click", closeSourceDialog);
  sourceDialog.addEventListener("click", (event) => {
    if (event.target === sourceDialog) closeSourceDialog();
  });
  sourceDialog.addEventListener("close", () => {
    document.body.classList.remove("modal-open");
  });

  render();
})();
