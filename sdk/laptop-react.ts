/*
 * React hooks for the zyke_laptop SDK. Copy this file and laptop.d.ts into a Vite + React page, with laptop.d.ts
 * inside your tsconfig's "include", and load the SDK as a classic script before your bundle so window.Laptop is
 * there when it runs:
 *
 *     <script src="https://cfx-nui-zyke_laptop/nui/sdk/laptop.js"></script>
 */
import { useCallback, useEffect, useRef, useState } from "react";

// Calls the newest handler on every event without listening again after each render
export const useLaptopEvent = <E extends ZykeLaptop.EventName>(event: E, handler: (data: ZykeLaptop.Events[E]) => void) => {
    const latest = useRef(handler);

    useEffect(() => {
        latest.current = handler;
    });

    useEffect(() => window.Laptop.on(event, (data) => latest.current(data)), [event]);
};

// The context once the laptop answered, null before that. Re-renders when the theme, OS, connection, visibility,
// params, devices or settings change
export const useLaptopContext = (): ZykeLaptop.Context | null => {
    const [context, setContext] = useState(() => window.Laptop.context);

    // The SDK updates one context object in place, so each change is copied to re-render
    useLaptopEvent("context", (next) => setContext({ ...next }));

    useEffect(() => {
        void window.Laptop.ready().then((ready) => setContext({ ...ready }));
    }, []);

    return context;
};

// What is plugged into the laptop's ports, empty before the laptop answered and outside it
export const useLaptopDevices = (): ZykeLaptop.Device[] => {
    const [devices, setDevices] = useState(() => window.Laptop.context?.devices ?? []);

    useLaptopEvent("devices", setDevices);

    useEffect(() => {
        void window.Laptop.ready().then((ready) => setDevices(ready.devices ?? []));
    }, []);

    return devices;
};

// The OS settings, such as volume and uiSounds for the page's own sounds; null before the laptop answered
export const useLaptopSettings = (): ZykeLaptop.Settings | null => {
    const [settings, setSettings] = useState(() => window.Laptop.context?.settings ?? null);

    useLaptopEvent("settings", setSettings);

    useEffect(() => {
        void window.Laptop.ready().then((ready) => setSettings(ready.settings ?? null));
    }, []);

    return settings;
};

// What your resource sent with SendAppMessage or SendSiteMessage
export const useLaptopMessage = <T>(handler: (data: T) => void) => useLaptopEvent("message", (data) => handler(data as T));

// POSTs to your resource's RegisterNUICallback(endpoint) and types the reply
export const laptopPost = <T = unknown>(endpoint: string, data?: unknown) => window.Laptop.post<T>(endpoint, data);

// The values every useLaptopState of the page keeps, one object by key
const savedValues = (): Record<string, unknown> => {
    const state = window.Laptop.context?.state;

    return state && typeof state === "object" && !Array.isArray(state) ? (state as Record<string, unknown>) : {};
};

// Like useState, but the laptop keeps the value for the app's window or the site's tab, so the page opens on it again
// after the laptop slept: closed, put away, a relog or a server restart. The value has to be JSON, and every key of the
// page together takes 16 KiB at most. Starts from initial until the laptop answered with a saved one
export const useLaptopState = <T>(key: string, initial: T): [T, (next: T) => void] => {
    const [value, setValue] = useState<T>(() => (key in savedValues() ? (savedValues()[key] as T) : initial));
    // A value the page set before the laptop answered wins over the saved one
    const changed = useRef(false);

    useEffect(() => {
        void window.Laptop.ready().then(() => {
            const saved = savedValues();

            if (!changed.current && key in saved) setValue(saved[key] as T);
        });
    }, [key]);

    const save = useCallback(
        (next: T) => {
            changed.current = true;
            setValue(next);
            void window.Laptop.saveState({ ...savedValues(), [key]: next }).catch(() => undefined);
        },
        [key]
    );

    return [value, save];
};

// What this page may use on this laptop now, kept current by the capabilities event
export const useLaptopCapabilities = (): ZykeLaptop.Capability[] => {
    const [capabilities, setCapabilities] = useState(() => window.Laptop.context?.capabilities ?? []);

    useLaptopEvent("capabilities", setCapabilities);

    useEffect(() => {
        void window.Laptop.ready().then((ready) => setCapabilities(ready.capabilities ?? []));
    }, []);

    return capabilities;
};

// The laptop's account, read once and again whenever the OS switches account. error is the code of a refusal, such as
// "denied" or "notRegistered"
export const useLaptopAccount = (): { account: ZykeLaptop.Account | null; error: ZykeLaptop.SdkErrorCode | null } => {
    const [state, setState] = useState<{ account: ZykeLaptop.Account | null; error: ZykeLaptop.SdkErrorCode | null }>({ account: null, error: null });

    const load = useCallback(() => {
        window.Laptop.account().then(
            (account) => setState({ account, error: null }),
            (error: ZykeLaptop.SdkError) => setState({ account: null, error: error.code ?? "failed" })
        );
    }, []);

    useLaptopEvent("account", load);

    useEffect(() => {
        void window.Laptop.ready().then(load);
    }, [load]);

    return state;
};

// One key of Laptop.storage: initial until the server answers, then the stored value, kept current when another
// laptop of the account changes it. set writes it and shows it at once; a refused write rolls back and rejects
export const useLaptopStorage = <T>(key: string, initial: T): [T, (value: T) => Promise<true>] => {
    const [value, setValue] = useState<T>(initial);
    const latest = useRef(value);

    useEffect(() => {
        latest.current = value;
    });

    useEffect(() => {
        let alive = true;

        void window.Laptop.ready()
            .then(() => window.Laptop.storage.get<T>(key))
            .then((stored) => alive && stored !== null && setValue(stored), () => undefined);

        return () => {
            alive = false;
        };
    }, [key]);

    useLaptopEvent("storage", (change: ZykeLaptop.StorageChange) => {
        if (change.key === key) setValue(change.value === null ? initial : (change.value as T));
    });

    const set = useCallback(
        (next: T) => {
            const previous = latest.current;

            setValue(next);

            return window.Laptop.storage.set(key, next).catch((error: unknown) => {
                setValue(previous);

                throw error;
            });
        },
        [key]
    );

    return [value, set];
};

// Joins Laptop.rooms(name) while mounted and leaves on unmount or another name. members stays current; error is the
// code of a refused join, such as "notRegistered" or "offline". room is null until joined and after a close
export const useLaptopRoom = (
    name: string,
    data?: unknown
): { room: ZykeLaptop.Room | null; members: ZykeLaptop.RoomMember[]; error: ZykeLaptop.SdkErrorCode | null } => {
    const [state, setState] = useState<{ room: ZykeLaptop.Room | null; members: ZykeLaptop.RoomMember[]; error: ZykeLaptop.SdkErrorCode | null }>({
        room: null,
        members: [],
        error: null,
    });
    const joinData = useRef(data);

    useEffect(() => {
        joinData.current = data;
    });

    useEffect(() => {
        let alive = true;
        let joined: ZykeLaptop.Room | null = null;
        const stops: (() => void)[] = [];
        const refresh = () => alive && joined && setState({ room: joined, members: joined.members.slice(), error: null });

        void window.Laptop.ready()
            .then(() => window.Laptop.rooms.join(name, joinData.current))
            .then(
                (room) => {
                    if (!alive) return void room.leave().catch(() => undefined);

                    joined = room;
                    stops.push(room.on("join", refresh), room.on("leave", refresh));
                    stops.push(room.on("close", () => alive && setState({ room: null, members: [], error: null })));
                    refresh();
                },
                (error: ZykeLaptop.SdkError) => alive && setState({ room: null, members: [], error: error.code ?? "failed" })
            );

        return () => {
            alive = false;
            stops.forEach((stop) => stop());
            void joined?.leave().catch(() => undefined);
        };
    }, [name]);

    return state;
};
