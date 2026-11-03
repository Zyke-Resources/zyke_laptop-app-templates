import { useState } from "react";
import { laptopPost } from "../laptop-react";
import { useT } from "../strings";
import type { Result, ServerInfo } from "../types";

// laptopPost goes to the RegisterNUICallback of the same name in client/app.lua, which asks the server
const ServerCard = () => {
    const t = useT();
    const [info, setInfo] = useState<ServerInfo | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [busy, setBusy] = useState(false);

    const ask = async () => {
        setBusy(true);

        const result = await laptopPost<Result<ServerInfo>>("GetServerInfo").catch(() => null);

        setBusy(false);
        setError(result?.ok ? null : (result?.error ?? "error:unavailable"));
        if (result?.ok) setInfo(result);
    };

    // The answer comes later as an OS notification and a message, see MessageCard
    const ping = async () => {
        const result = await laptopPost<Result>("Ping").catch(() => null);

        setError(result?.ok ? null : (result?.error ?? "error:unavailable"));
    };

    return (
        <section className="card">
            <h2>{t("server:title")}</h2>
            {info && (
                <dl className="stats">
                    <dt>{t("server:players")}</dt>
                    <dd>{info.players}</dd>
                    <dt>{t("server:time")}</dt>
                    <dd>{info.time}</dd>
                </dl>
            )}
            {error && <p className="error">{t(error)}</p>}
            <div className="row">
                <button className="button suggested" disabled={busy} onClick={() => void ask()}>
                    {busy ? t("server:asking") : t("server:ask")}
                </button>
                <button className="button" onClick={() => void ping()}>
                    {t("server:ping")}
                </button>
            </div>
        </section>
    );
};

export default ServerCard;
