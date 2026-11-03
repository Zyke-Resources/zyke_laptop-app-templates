import { useEffect, useState } from "react";
import { laptopPost } from "./laptop-react";
import { StringsContext } from "./strings";
import type { Setup } from "./types";
import Header from "./components/Header";
import NameCard from "./components/NameCard";
import ServerCard from "./components/ServerCard";
import MessageCard from "./components/MessageCard";

const App = () => {
    const [strings, setStrings] = useState<Setup["strings"] | null>(null);

    useEffect(() => {
        void laptopPost<Setup>("Setup").then((setup) => setStrings(setup.strings));
    }, []);

    if (!strings) return null;

    return (
        <StringsContext.Provider value={strings}>
            <main className="app">
                <Header />
                <NameCard />
                <ServerCard />
                <MessageCard />
            </main>
        </StringsContext.Provider>
    );
};

export default App;
