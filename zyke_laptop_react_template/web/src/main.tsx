import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./styles.css";

if (!window.Laptop) throw new Error("window.Laptop is missing, index.html has to load laptop.js before the bundle");

// The mocks answer laptopPost while the page runs in a normal browser with npm run dev, and are left out of the build
if (import.meta.env.DEV) await import("./mock");

createRoot(document.getElementById("root")!).render(
    <StrictMode>
        <App />
    </StrictMode>
);
