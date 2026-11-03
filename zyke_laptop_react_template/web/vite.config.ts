import { createReadStream, existsSync } from "node:fs";
import { dirname, join, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import react from "@vitejs/plugin-react";
import { defineConfig, type Plugin } from "vite";

const sdkUrl = "https://cfx-nui-zyke_laptop/nui/sdk/laptop.js";
const devPrefix = "/@zyke_laptop/nui/";

// The zyke_laptop folder for the dev server: ZYKE_LAPTOP_PATH when set, otherwise next to this resource or next to its
// category folder, the same two places the plain templates look
const findLaptop = (): string | null => {
    const resourceRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
    const candidates = process.env.ZYKE_LAPTOP_PATH ? [resolve(process.env.ZYKE_LAPTOP_PATH)] : [resolve(resourceRoot, "../zyke_laptop"), resolve(resourceRoot, "../../zyke_laptop")];

    return candidates.find((dir) => existsSync(join(dir, "nui/sdk/laptop.js"))) ?? null;
};

// In game the page loads the SDK from the laptop itself. A normal browser can't reach cfx-nui-zyke_laptop, so the dev
// server serves the laptop's nui/sdk and nui/fonts folders under /@zyke_laptop/nui/ and points the script tag there
const laptopSdk = (): Plugin => {
    const laptop = findLaptop();

    return {
        name: "zyke-laptop-sdk",
        apply: "serve",
        configureServer(server) {
            if (!laptop) {
                server.config.logger.warn("zyke_laptop not found, set ZYKE_LAPTOP_PATH to its folder to load the SDK");

                return;
            }

            const root = join(laptop, "nui");

            server.middlewares.use(devPrefix, (req, res, next) => {
                const file = join(root, decodeURIComponent((req.url ?? "/").split("?")[0]));
                if (!file.startsWith(root + sep) || !existsSync(file)) return next();

                res.setHeader("Content-Type", file.endsWith(".js") ? "text/javascript" : "font/woff2");
                createReadStream(file).pipe(res);
            });
        },
        transformIndexHtml: (html) => html.replace(sdkUrl, devPrefix + "sdk/laptop.js"),
    };
};

export default defineConfig({
    // Relative asset paths, so the build works from https://cfx-nui-<resource>/web/dist/
    base: "./",
    plugins: [react(), laptopSdk()],
    // src/mock.ts reads ../locales/en.lua
    server: { fs: { allow: [".."] } },
    build: {
        // FiveM's NUI runs Chromium 103
        target: "chrome103",
        cssTarget: "chrome103",
    },
});
