import { useLaptopContext } from "../laptop-react";
import { useT } from "../strings";

const osNames: Record<ZykeLaptop.OsId, string> = { facade: "Facade", lumen: "Lumen", solace: "Solace", veil: "Veil" };

// Reads the OS and theme from the laptop's context, which re-renders this when the player changes either
const Header = () => {
    const t = useT();
    const context = useLaptopContext();

    const summary = !context ? "" : context.standalone ? t("theme:browser") : t("theme:summary", osNames[context.os], t(`theme:${context.theme}`));

    return (
        <header className="header">
            <h1>{t("app:name")}</h1>
            <p className="dim">{summary}</p>
        </header>
    );
};

export default Header;
