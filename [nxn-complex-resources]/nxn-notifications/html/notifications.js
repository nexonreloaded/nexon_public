/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║          NEXON RELOADED — Notification System                ║
 * ║                    notifications.js                          ║
 * ╚══════════════════════════════════════════════════════════════╝
 *
 * Csak renderelés — minden logika (queue, timer, config) Lua oldalon van.
 * A Lua küld NUI message-eket, ez csak megjeleníti / eltünteti.
 *
 * ── BEJÖVŐ NUI ESEMÉNYEK ───────────────────────────────────────
 *
 *  { action: "init",        data: { config } }
 *  { action: "simple",      data: { id, icon, category, title, color, duration, accentColor } }
 *  { action: "status",      data: { id, icon, category, title, color, value, maxValue, subtext, accentColor } }
 *  { action: "interaction", data: { id, name, playerId, message, progress, accentColor } }
 *  { action: "discovery",   data: { id, tag, title, imageUrl, meta: [{icon, text}], accentColor } }
 *  { action: "prompt",      data: { id, key, text, highlight, accentColor } }
 *  { action: "update",      data: { id, ...fields } }
 *  { action: "dismiss",     data: { id } }
 *  { action: "dismissAll",  data: {} }
 */

(() => {
    "use strict";

    // ── Refs ───────────────────────────────────────────────────────
    const stackEl  = () => document.getElementById("nxn-stack");
    const promptEl = () => document.getElementById("nxn-prompt-container");

    // ── Config (init-kor érkezik Lua-ból) ──────────────────────────
    let CFG = {
        animIn:       350,
        animOut:      300,
        enterStyle:   "slide-fade",
        exitStyle:    "slide-fade",
        errorShake:   true,
        stackPos:     "top-right",
        promptPos:    "bottom-center",
        offsetX:      32,
        offsetY:      96,
    };

    // ── Segédfüggvények ────────────────────────────────────────────
    const esc = (s) => String(s ?? "")
        .replace(/&/g,"&amp;")
        .replace(/</g,"&lt;")
        .replace(/>/g,"&gt;")
        .replace(/"/g,"&quot;");

    const setCSSVar = (el, key, val) => el.style.setProperty(key, val);

    // ── Pozíció alkalmazása ────────────────────────────────────────
    const applyPosition = () => {
        const stack  = stackEl();
        const prompt = promptEl();
        if (!stack || !prompt) return;

        // Stack
        stack.className = "nxn-stack";
        const sMap = {
            "top-right":    "nxn-pos--top-right",
            "top-left":     "nxn-pos--top-left",
            "bottom-right": "nxn-pos--bottom-right",
            "bottom-left":  "nxn-pos--bottom-left",
        };
        stack.classList.add(sMap[CFG.stackPos] ?? "nxn-pos--top-right");
        setCSSVar(stack, "--nxn-offset-x", CFG.offsetX + "px");
        setCSSVar(stack, "--nxn-offset-y", CFG.offsetY + "px");

        // Prompt
        prompt.className = "nxn-prompt-container";
        const pMap = {
            "bottom-center": "nxn-prompt--bottom-center",
            "bottom-left":   "nxn-prompt--bottom-left",
            "bottom-right":  "nxn-prompt--bottom-right",
        };
        prompt.classList.add(pMap[CFG.promptPos] ?? "nxn-prompt--bottom-center");

        // Animáció CSS változók
        document.documentElement.style.setProperty("--nxn-anim-in",  CFG.animIn  + "ms");
        document.documentElement.style.setProperty("--nxn-anim-out", CFG.animOut + "ms");
    };

    // ── Animáció ───────────────────────────────────────────────────
    const ENTER = {
        "slide-fade": "nxn-enter--slide-fade",
        "slide":      "nxn-enter--slide",
        "fade":       "nxn-enter--fade",
        "scale":      "nxn-enter--scale",
    };
    const EXIT = {
        "slide-fade": "nxn-exit--slide-fade",
        "slide":      "nxn-exit--slide",
        "fade":       "nxn-exit--fade",
        "scale":      "nxn-exit--scale",
    };

    const animateIn = (el, isPrompt = false) => {
        const cls = isPrompt
            ? "nxn-prompt-enter"
            : (ENTER[CFG.enterStyle] ?? "nxn-enter--slide-fade");
        el.classList.add(cls);
        requestAnimationFrame(() => requestAnimationFrame(() => {
            el.classList.add("nxn-entered");
        }));
    };

    const animateOut = (el, cb, isPrompt = false) => {
        if (isPrompt) {
            el.classList.remove("nxn-entered");
            el.classList.add("nxn-exit--fade");
        } else {
            el.classList.remove("nxn-entered");
            el.classList.add(EXIT[CFG.exitStyle] ?? "nxn-exit--slide-fade");
        }
        setTimeout(() => { el.remove(); cb?.(); }, CFG.animOut);
    };

    // ── Dismiss ────────────────────────────────────────────────────
    const dismiss = (id) => {
        const el = document.getElementById(id);
        if (!el) return;
        const isPrompt = el.closest("#nxn-prompt-container") !== null;
        animateOut(el, null, isPrompt);
    };

    const dismissAll = () => {
        document.querySelectorAll("[data-nxn-id]").forEach(el => {
            const id = el.dataset.nxnId;
            dismiss(id);
        });
    };

    // ── Update ─────────────────────────────────────────────────────
    const update = (id, data) => {
        const el = document.getElementById(id);
        if (!el) return;

        if (data.title != null) {
            const t = el.querySelector("[data-field='title']");
            if (t) t.textContent = data.title;
        }
        if (data.value != null) {
            const pct = Math.max(0, Math.min(100, data.value));
            const fill = el.querySelector("[data-field='progress-fill']");
            if (fill) fill.style.width = pct + "%";
            const titleEl = el.querySelector("[data-field='title']");
            if (titleEl && data.label) titleEl.textContent = data.label;
        }
        if (data.progress != null) {
            const pct = Math.max(0, Math.min(100, data.progress));
            const fill = el.querySelector("[data-field='interaction-progress']");
            if (fill) fill.style.width = pct + "%";
        }
        if (data.message != null) {
            const m = el.querySelector("[data-field='message']");
            if (m) m.textContent = data.message;
        }
        if (data.accentColor != null) {
            el.style.borderLeftColor = data.accentColor;
        }
    };

    // ══════════════════════════════════════════════════════════════
    // RENDER FÜGGVÉNYEK
    // ══════════════════════════════════════════════════════════════

    // ── 1. Simple ─────────────────────────────────────────────────
    const renderSimple = (d) => {
        const color = esc(d.accentColor ?? "#e80043");
        const el = document.createElement("div");
        el.id = esc(d.id);
        el.dataset.nxnId = esc(d.id);
        el.className = "nxn-notification nxn-simple glass-panel";
        el.style.borderLeftColor = color;

        if (CFG.errorShake && d.shake) el.classList.add("nxn-shake");

        el.innerHTML = `
            <div class="nxn-simple__icon">
                <span class="material-symbols-outlined filled" style="color:${color}">${esc(d.icon ?? "notifications")}</span>
            </div>
            <div class="nxn-simple__body">
                <span class="nxn-simple__category">${esc(d.category ?? "")}</span>
                <span class="nxn-simple__title" data-field="title">${esc(d.title ?? "")}</span>
            </div>
            <div class="nxn-timer-bar">
                <div class="nxn-timer-bar__fill" style="color:${color}"></div>
            </div>
        `;

        stackEl().appendChild(el);
        animateIn(el);
        startTimerBar(el, d.duration);
    };

    // ── 2. Status ─────────────────────────────────────────────────
    const renderStatus = (d) => {
        const color = esc(d.accentColor ?? "#d53d18");
        const pct   = Math.max(0, Math.min(100, d.value ?? 100));
        const el    = document.createElement("div");
        el.id = esc(d.id);
        el.dataset.nxnId = esc(d.id);
        el.className = "nxn-notification nxn-status glass-panel";
        el.style.borderLeftColor = color;

        el.innerHTML = `
            <div class="nxn-status__header">
                <div class="nxn-status__body">
                    <span class="nxn-status__category">${esc(d.category ?? "")}</span>
                    <span class="nxn-status__title" data-field="title">${esc(d.title ?? "")}</span>
                </div>
                <span class="material-symbols-outlined nxn-status__icon nxn-pulse" style="color:${color}">${esc(d.icon ?? "monitor_heart")}</span>
            </div>
            <div class="nxn-progress-track">
                <div class="nxn-progress-fill" data-field="progress-fill"
                     style="width:${pct}%; background:${color}"></div>
            </div>
            ${d.subtext ? `<div class="nxn-status__sub" style="color:${color}">${esc(d.subtext)}</div>` : ""}
            <div class="nxn-timer-bar">
                <div class="nxn-timer-bar__fill" style="color:${color}"></div>
            </div>
        `;

        stackEl().appendChild(el);
        animateIn(el);
        startTimerBar(el, d.duration);
    };

    // ── 3. Interaction ────────────────────────────────────────────
    const renderInteraction = (d) => {
        const color = esc(d.accentColor ?? "#ffffff");
        const prog  = Math.max(0, Math.min(100, d.progress ?? 0));
        const el    = document.createElement("div");
        el.id = esc(d.id);
        el.dataset.nxnId = esc(d.id);
        el.className = "nxn-notification nxn-interaction glass-panel";
        el.style.borderLeftColor = color;

        el.innerHTML = `
            <div class="nxn-scanline"></div>
            <div class="nxn-interaction__glow"></div>
            <div class="nxn-interaction__header">
                <div class="nxn-interaction__avatar">
                    <span class="material-symbols-outlined" style="color:#fff">${esc(d.icon ?? "person_search")}</span>
                </div>
                <div class="nxn-interaction__meta">
                    <span class="nxn-interaction__category">${esc(d.category ?? "Interaction")}</span>
                    <div class="nxn-interaction__name-row">
                        <span class="nxn-interaction__name">${esc(d.name ?? "")}</span>
                        ${d.playerId != null ? `<span class="nxn-interaction__id">[ID: ${esc(d.playerId)}]</span>` : ""}
                    </div>
                </div>
            </div>
            <p class="nxn-interaction__message" data-field="message">"${esc(d.message ?? "")}"</p>
            <div class="nxn-interaction__progress-track">
                <div class="nxn-interaction__progress-fill" data-field="interaction-progress"
                     style="width:${prog}%; background:${color}"></div>
            </div>
        `;

        stackEl().appendChild(el);
        animateIn(el);
    };

    // ── 4. Discovery ──────────────────────────────────────────────
    const renderDiscovery = (d) => {
        const color = esc(d.accentColor ?? "#e80043");
        const el    = document.createElement("div");
        el.id = esc(d.id);
        el.dataset.nxnId = esc(d.id);
        el.className = "nxn-notification nxn-discovery glass-panel";
        el.style.borderLeftColor = color;

        const metaHTML = (d.meta ?? []).map(m => `
            <div class="nxn-discovery__meta-item">
                <span class="material-symbols-outlined">${esc(m.icon)}</span>
                ${esc(m.text)}
            </div>
        `).join("");

        const imgHTML = d.imageUrl
            ? `<div class="nxn-discovery__image-wrap">
                   <img src="${esc(d.imageUrl)}" alt=""/>
                   <div class="nxn-discovery__image-fade"></div>
               </div>`
            : "";

        el.innerHTML = `
            ${imgHTML}
            <div class="nxn-discovery__body">
                <div class="nxn-discovery__tag" style="color:${color}">${esc(d.tag ?? "New Location")}</div>
                <div class="nxn-discovery__title">${esc(d.title ?? "")}</div>
                ${metaHTML ? `<div class="nxn-discovery__meta-row">${metaHTML}</div>` : ""}
            </div>
            <div class="nxn-timer-bar">
                <div class="nxn-timer-bar__fill" style="color:${color}"></div>
            </div>
        `;

        stackEl().appendChild(el);
        animateIn(el);
        startTimerBar(el, d.duration);
    };

    // ── 5. Prompt ─────────────────────────────────────────────────
    const renderPrompt = (d) => {
        const color = esc(d.accentColor ?? "#e80043");
        const el    = document.createElement("div");
        el.id = esc(d.id);
        el.dataset.nxnId = esc(d.id);
        el.className = "nxn-prompt glass-panel";

        // bottom-center esetén az animáció translateX-et is tartalmaz
        const isCenter = promptEl().classList.contains("nxn-prompt--bottom-center");
        if (isCenter) el.style.position = "relative";

        el.innerHTML = `
            <div class="nxn-prompt__key kinetic-gradient" style="background:linear-gradient(135deg,${color},${color}cc)">${esc(d.key ?? "E")}</div>
            <span class="nxn-prompt__text">
                ${esc(d.text ?? "")}
                ${d.highlight ? `<span class="nxn-prompt__highlight" style="color:${color}">${esc(d.highlight)}</span>` : ""}
            </span>
        `;

        promptEl().appendChild(el);
        animateIn(el, true);
    };

    // ── Timer bar animáció ─────────────────────────────────────────
    const startTimerBar = (el, duration) => {
        if (!duration || duration <= 0) return;
        const fill = el.querySelector(".nxn-timer-bar__fill");
        if (!fill) return;
        // Kis delay hogy a CSS transition ne rögtön fusson
        requestAnimationFrame(() => {
            fill.style.transition = `transform ${duration}ms linear`;
            fill.style.transform  = "scaleX(1)";
            requestAnimationFrame(() => {
                fill.style.transform = "scaleX(0)";
            });
        });
    };

    // ══════════════════════════════════════════════════════════════
    // NUI MESSAGE HANDLER
    // ══════════════════════════════════════════════════════════════
    window.addEventListener("message", (event) => {
        const { action, data } = event.data ?? {};
        if (!action) return;

        switch (action) {
            case "init":
                CFG = { ...CFG, ...data };
                applyPosition();
                break;
            case "simple":
                renderSimple(data);
                break;
            case "status":
                renderStatus(data);
                break;
            case "interaction":
                renderInteraction(data);
                break;
            case "discovery":
                renderDiscovery(data);
                break;
            case "prompt":
                renderPrompt(data);
                break;
            case "update":
                update(data.id, data);
                break;
            case "dismiss":
                dismiss(data.id);
                break;
            case "dismissAll":
                dismissAll();
                break;
        }
    });

    // Pozíció alkalmazása betöltéskor (default értékekkel)
    window.addEventListener("DOMContentLoaded", applyPosition);

})();
