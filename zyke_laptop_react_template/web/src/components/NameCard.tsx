import { useLaptopState } from "../laptop-react";
import { useT } from "../strings";

// useLaptopState works like useState, but the laptop gives the value back when the app opens again after it slept
const NameCard = () => {
    const t = useT();
    const [name, setName] = useLaptopState("name", "");

    return (
        <section className="card">
            <h2>{t("name:title")}</h2>
            <input className="entry" value={name} maxLength={32} placeholder={t("name:placeholder")} onChange={(e) => setName(e.target.value)} />
            {name.trim() && <p>{t("name:greeting", name.trim())}</p>}
            <p className="dim">{t("name:hint")}</p>
        </section>
    );
};

export default NameCard;
