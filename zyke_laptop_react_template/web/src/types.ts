// What the Lua side answers. Every server reply carries ok, and a locale key in error when it is false
export interface Setup {
    strings: Record<string, string>;
}

export type Result<T = object> = (T & { ok: true }) | { ok: false; error: string };

export interface ServerInfo {
    players: number;
    time: string;
}

// Sent by client/app.lua with SendAppMessage
export interface Pong {
    count: number;
    time: string;
}
