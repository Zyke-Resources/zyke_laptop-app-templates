// The stopwatch program. The Terminal runs this page hidden, so it draws with Laptop.terminal.screen and keeps time with
// timers: the frame is never on screen, so requestAnimationFrame would not run
(function () {
    "use strict";

    const Laptop = window.Laptop;
    if (!Laptop) return;

    const term = Laptop.terminal;
    let strings = {};

    // Locale keys with %s placeholders, filled in order
    const t = (key, ...values) => values.reduce((text, value) => text.replace("%s", value), strings[key] ?? key);

    const format = (ms) => {
        const minutes = Math.floor(ms / 60000);
        const seconds = Math.floor(ms / 1000) % 60;
        const tenths = Math.floor(ms / 100) % 10;

        return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}.${tenths}`;
    };

    const run = async () => {
        let size = await term.screen.open();
        let startedAt = null;
        let elapsed = 0;
        const laps = [];

        const now = () => elapsed + (startedAt === null ? 0 : Date.now() - startedAt);

        // One frame: a title bar, the time in the middle and the laps under it. Each row is a string or a list of
        // segments; rows past size.rows are dropped and each row is cut at size.cols
        const draw = () => {
            const rows = new Array(size.rows).fill("");
            const time = format(now());
            const middle = Math.max(2, Math.floor(size.rows / 2) - 1);
            const pad = (text) => " ".repeat(Math.max(0, Math.floor((size.cols - text.length) / 2))) + text;

            rows[0] = [
                { text: ` ${t("stopwatch:title")} `, color: "#ffffff", bg: "#1c71d8" },
                { text: ` ${t(startedAt === null ? "stopwatch:stopped" : "stopwatch:running")}  `, tone: startedAt === null ? "warning" : "success" },
                { text: t("stopwatch:keys"), tone: "dim" },
            ];
            rows[middle] = { text: pad(time), tone: "bold" };

            laps.slice(-Math.max(0, size.rows - middle - 3)).forEach((lap, index) => {
                rows[middle + 2 + index] = { text: pad(`${t("stopwatch:lap", lap.number)}  ${format(lap.at)}`), tone: "dim" };
            });

            term.screen.draw(rows);
        };

        const timer = setInterval(draw, 100);

        const finish = () => {
            clearInterval(timer);
            term.screen.close();
            term.print(t("stopwatch:result", format(now())), "accent");
            term.exit();
        };

        // Every key while the screen is open: { key, code, ctrl, alt, shift }
        term.onKey((key) => {
            const name = key.key.toLowerCase();

            if (name === "q" || name === "escape") return finish();

            if (name === " ") {
                if (startedAt === null) startedAt = Date.now();
                else {
                    elapsed = now();
                    startedAt = null;
                }
            } else if (name === "l" && now() > 0) {
                laps.push({ number: laps.length + 1, at: now() });
            } else if (name === "r") {
                startedAt = null;
                elapsed = 0;
                laps.length = 0;
            }

            draw();
        });

        // The window or the font size changed
        term.onResize((next) => {
            size = next;
            draw();
        });

        // Ctrl+C or the window closing: the Terminal ends the program a moment later
        term.onCancel(() => clearInterval(timer));

        draw();
    };

    // Outside the game no client.lua answers Setup, so read the ["key"] = "value" lines of locales/en.lua instead
    if (!Laptop.inGame) {
        Laptop.mock("Setup", () =>
            fetch("../locales/en.lua")
                .then((response) => response.text())
                .then((source) => ({ strings: Object.fromEntries([...source.matchAll(/\["([^"]+)"\]\s*=\s*"((?:[^"\\]|\\.)*)"/g)].map((match) => [match[1], match[2]])) }))
        );
    }

    Laptop.ready()
        .then(() => Laptop.post("Setup"))
        .then((setup) => {
            strings = setup?.strings ?? {};
        })
        .catch(() => {})
        .then(() => {
            // Opened as a normal page, not by the Terminal
            if (!term.active) {
                document.getElementById("note").textContent = t("stopwatch:notTerminal");

                return;
            }

            run();
        });
})();
