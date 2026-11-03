import { useState } from "react";
import { useLaptopMessage } from "../laptop-react";
import { useT } from "../strings";
import type { Pong } from "../types";

// Shows what client/app.lua pushed with SendAppMessage. Only an open app gets these, so keep the source of truth on
// the server and treat messages as hints to refresh
const MessageCard = () => {
    const t = useT();
    const [pong, setPong] = useState<Pong | null>(null);

    useLaptopMessage<Pong>(setPong);

    return (
        <section className="card">
            <h2>{t("message:title")}</h2>
            <p className={pong ? "" : "dim"}>{pong ? t("message:received", pong.count, pong.time) : t("message:empty")}</p>
        </section>
    );
};

export default MessageCard;
