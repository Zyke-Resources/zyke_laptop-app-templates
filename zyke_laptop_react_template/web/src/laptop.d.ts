/*
 * Types for the zyke_laptop SDK, window.Laptop from https://cfx-nui-zyke_laptop/nui/sdk/laptop.js.
 *
 * A global declaration file: copy it into your project and add it to tsconfig's "include", or reference it with
 * /// <reference path="./laptop.d.ts" />. Its types live in the ZykeLaptop namespace, such as ZykeLaptop.Context.
 */

declare namespace ZykeLaptop {
    // Facade is like Windows 11 with the browser Ledge, Lumen like Ubuntu with Emberfox, Veil like Tails with Veil Browser,
    // Solace like macOS with Savanna
    type OsId = "facade" | "lumen" | "veil" | "solace";

    type Theme = "light" | "dark";

    type Accent = "blue" | "teal" | "green" | "yellow" | "orange" | "red" | "pink" | "purple" | "slate";

    // Resolved CSS colours of the OS, also set as --laptop-<kebab-case key>, such as --laptop-window-bg
    interface Palette {
        accent: string;
        accentBg: string;
        accentFg: string;
        windowBg: string;
        windowFg: string;
        viewBg: string;
        viewFg: string;
        headerbarBg: string;
        sidebarBg: string;
        cardBg: string;
        popoverBg: string;
        borders: string;
        dimFg: string;
        hoverBg: string;
        buttonBg: string;
        entryBg: string;
        success: string;
        warning: string;
        error: string;
        destructiveBg: string;
    }

    // CSS lengths of the OS's shapes, also set as --laptop-radius, --laptop-radius-control and --laptop-control-height
    interface Shape {
        // Cards and panels
        radius: string;
        // Buttons and entries
        radiusControl: string;
        controlHeight: string;
    }

    interface Connection {
        status: "disconnected" | "connecting" | "connected" | "failed";
        connected: boolean;
        exitIp: string | null;
    }

    interface Settings {
        language: string;
        clock24h: boolean;
        securityLevel: "standard" | "safer" | "safest";
        uiSounds: boolean;
        volume: number;
        doNotDisturb: boolean;
    }

    type PortKind = "usbc" | "usba" | "hdmi" | "audio";

    // Something plugged into one of the laptop's ports
    interface Device {
        // Port id, such as "usba" or "usbc1"
        port: string;
        kind: PortKind;
        // "rear" on a desktop computer, whose ports face back
        side: "left" | "right" | "rear";
        // Device type id, such as "data_stick", "boot_stick" or one a resource registered
        type: string;
        // Inventory item name and its label
        item: string;
        label: string;
    }

    interface ThemeData {
        theme: Theme;
        accent: Accent;
        palette: Palette;
        os: OsId;
        shape: Shape;
    }

    interface Context extends ThemeData {
        protocol: number;
        // Set when the page runs on its own, outside the laptop
        standalone?: true;
        kind: "app" | "site" | null;
        // App id or site id
        id: string | null;
        windowId: string | null;
        resource: string | null;
        params: Record<string, unknown>;
        // The recovery toolkit's live session, where os is "lumen"
        toolkit: boolean;
        connection: Connection;
        settings: Settings;
        // Whether the laptop's screen is open
        visible: boolean;
        // What is plugged into the laptop's ports; empty ports are left out
        devices: Device[];
        // "dui" in game, where the OS runs on the laptop's own screen and the SDK makes typing, modifier clicks, double
        // clicks and <select> lists work; unset on a page opened on its own and in the browser preview
        display?: "dui";
        // What the page last kept with saveState, given back after the laptop slept
        state?: unknown;
        // Sites only: the address the tab shows
        url?: string;
        host?: string;
        path?: string;
        search?: string;
        // Pages shown inside a Shroud conversation
        chat?: { messageId: string };
        // What this page may use on this laptop now, see Laptop.can
        capabilities: Capability[];
        // Files the app was opened with, such as a document double-clicked in Files
        files?: OpenedFile[];
        // Why the app was opened, when the OS opened it for a notification's action
        launch?: { notificationAction?: NotificationActionEvent };
    }

    interface Events {
        ready: Context;
        context: Context;
        // What SendAppMessage or SendSiteMessage sent
        message: unknown;
        params: Record<string, unknown>;
        theme: ThemeData;
        connection: Connection;
        visibility: { visible: boolean };
        devices: Device[];
        // The OS settings, sent when one of them changes, such as the volume or UI sounds
        settings: Settings;
        // Sites only: the tab moved to another of the site's addresses through pushUrl, back or forward, without
        // loading the page again. state is what the page saved for that address, like history.state
        location: Location;
        capabilities: Capability[];
        // The OS signed in, out or switched account; file handles from before are gone, read account() again
        account: undefined;
        notificationAction: NotificationActionEvent;
        filesOpened: OpenedFile[];
        // Another laptop of the same account changed this app's storage
        storage: StorageChange;
        // The app's cast started, stopped, or the screen asks for a fresh snapshot
        cast: CastEvent;
    }

    interface Location {
        url: string;
        host: string;
        path: string;
        search: string;
        state?: unknown;
    }

    type EventName = keyof Events;

    interface NotifyOptions {
        title: string;
        text?: string;
        // Lucide icon name or an image URL, relative paths resolve against the page
        icon?: string;
        // Milliseconds, 1000 to 30000
        duration?: number;
        // A notification of this app with the same id is replaced
        id?: string;
        // Two at most
        actions?: NotifyAction[];
        // JSON of 1 KiB at most, handed back with the action
        data?: unknown;
        // Played as the banner shows instead of the notification chime, null for a silent banner. Notifications only
        // chime while the laptop's screen is open, and follow the player's volume, UI-sounds switch and Do Not Disturb
        sound?: AppSound | "notification" | null;
    }

    // The OS's own sounds a page may play, in the voice of the OS it runs on
    type AppSound = "click" | "send" | "receive" | "success" | "error";

    interface SoundApi {
        // Only the player at the laptop hears it, with their volume, UI-sounds switch and Do Not Disturb. One per 60 ms,
        // faster calls reject with "rateLimited"; resolves without a sound in a normal browser
        play(name: AppSound): Promise<true>;
    }

    interface NotifyAction {
        // Letters, digits, _ and -, up to 32
        id: string;
        // Up to 24 characters, in the page's language
        label: string;
    }

    interface NotificationActionEvent {
        notificationId: string;
        // null when the notification itself was clicked
        action: string | null;
        data?: unknown;
    }

    type Capability = "files" | "documents" | "account" | "pay" | "storage" | "badge" | "notifyActions" | "share" | "clipboard" | "clipboardRead" | "cast" | "rooms";

    type SdkErrorCode =
        | "invalid"
        | "unsupported"
        | "notRegistered"
        | "notAllowed"
        | "noAccess"
        | "notLicensed"
        | "denied"
        | "cancelled"
        | "busy"
        | "rateLimited"
        | "tooLarge"
        | "quota"
        | "notFound"
        | "gone"
        | "offline"
        | "notReady"
        | "noFunds"
        | "expired"
        | "timeout"
        | "failed";

    // What SDK calls reject with. message is readable English for logs, code is what a page branches on
    interface SdkError extends globalThis.Error {
        code: SdkErrorCode;
    }

    type FileKind = "text" | "image" | "audio" | "video" | "archive" | "key" | "binary";

    // Extensions without the dot, lower case
    interface FileType {
        label?: string;
        extensions: string[];
    }

    type StartIn = "documents" | "persistent" | "stick";

    // A file the player picked. Only this window may use it, until it closes, the account changes or a stick it is on
    // leaves its port. path is for showing; calls take the handle or its id
    interface FileHandle {
        id: string;
        name: string;
        path: string;
        kind: FileKind;
        // Bytes
        size: number;
        // Milliseconds since the epoch
        modified: number;
        location: "home" | "persistent" | "stick";
        readOnly: boolean;
    }

    // Text files come with content, images with an address the page can show
    interface OpenedFile extends FileHandle {
        content?: string;
        src?: string;
    }

    interface OpenFileOptions {
        types?: FileType[];
        // The chooser picks one file for now, the answer is still a list
        multiple?: boolean;
        startIn?: StartIn;
    }

    interface SaveFileOptions {
        // Such as "March.ledger"; the part before the extension starts selected
        suggestedName: string;
        content: string;
        types?: FileType[];
        startIn?: StartIn;
    }

    interface FilesApi {
        // Rejects with "cancelled" when nothing was picked
        open(options?: OpenFileOptions): Promise<OpenedFile[]>;
        save(options: SaveFileOptions): Promise<FileHandle>;
        read(handle: FileHandle | string): Promise<OpenedFile>;
        // Overwrites a file this window opened or saved, without asking again
        write(handle: FileHandle | string, content: string): Promise<FileHandle>;
        release(handle: FileHandle | string): Promise<true>;
    }

    interface AccountJob {
        name: string;
        label: string;
        grade: number;
        gradeLabel: string;
        onDuty: boolean;
    }

    // "live" is Veil or another system booted from a stick, which has no account
    interface Account {
        kind: "nimbus" | "local" | "guest" | "live";
        name: string;
        address: string | null;
        // Stable for this account and app, random for each guest and live session. Not proof of anything: the
        // resource reads the same value on its server with GetLaptopAccount
        appUserId: string;
        os: OsId;
        // Only while the server shares jobs, never on Veil or as guest
        job?: AccountJob;
    }

    interface ClipboardApi {
        // 16384 characters at most
        writeText(text: string): Promise<true>;
        // What was last copied in this OS session, needs the "clipboard" permission
        readText(): Promise<string>;
    }

    interface OpenUrlOptions {
        // A site navigates its own tab unless this is set
        newTab?: boolean;
    }

    interface PushUrlOptions {
        // Swaps the address the tab shows instead of adding a history entry, like history.replaceState
        replace?: boolean;
    }

    // The player's laptop racks through Laptop.racks, as Hive shows them
    namespace Racks {
        type Role = "owner" | "member";

        type LaptopState = "off" | "idle" | "running" | "throttled" | "overheated" | "noBoard" | "noMemory";

        interface Summary {
            id: number;
            name: string;
            role: Role;
            on: boolean;
            // The breaker switched it off for drawing more than its supply
            tripped: boolean;
            laptops: number;
            slots: number;
            // Watts
            draw: number;
            // In the server's compute unit, such as MH/s
            compute: number;
        }

        interface Profile {
            id: string;
            // Multipliers of each laptop's draw and compute, and heat added to it
            power: number;
            compute: number;
            heat: number;
        }

        interface List {
            racks: Summary[];
            unit: string;
            profiles: Profile[];
        }

        interface Laptop {
            slot: number;
            serial: string;
            cpu?: string;
            threads: number;
            // Gigabytes
            memory: number;
            state: LaptopState;
            draw: number;
            compute: number;
            // 0 to 1, as are dust and paste (1 is fresh paste)
            heat: number;
            // 0 to 1, the share of its compute and hashrate it keeps for its heat
            throttle: number;
            dust?: number;
            paste?: number;
            hours: number;
            skin?: string;
        }

        interface WorkloadStatus {
            text?: string;
            key?: string;
            args?: Array<string | number>;
            // 0 to 1
            progress?: number;
        }

        // What one unit of compute earns an hour, such as 0.002 LTC for a mining pool, for an estimate
        interface WorkloadEarns {
            perUnitHour: number;
            unit: string;
        }

        interface Workload {
            id: string;
            label: string;
            description?: string;
            // Lucide icon name
            icon: string;
            earns?: WorkloadEarns;
            // Percent of the rack's compute, 0 to 100
            share: number;
            status?: WorkloadStatus;
            // Its resource is stopped and the share waits for it
            missing?: boolean;
        }

        interface Detail {
            id: number;
            name: string;
            role: Role;
            owner?: string;
            on: boolean;
            tripped: boolean;
            profile: string;
            // What the rack would draw and give with each profile
            profiles: Array<{ id: string; draw: number; compute: number }>;
            slots: number;
            // Watts the rack may draw before its breaker trips
            supply: number;
            draw: number;
            compute: number;
            // Share of compute the workloads take, 0 to 1
            load: number;
            laptops: Laptop[];
            workloads: Workload[];
            members: Array<{ name: string }>;
            maxMembers: number;
            // [unix seconds, compute, draw], oldest first
            history: Array<[number, number, number]>;
        }

        interface WorkloadInfo {
            id: string;
            label: string;
            description?: string;
            icon: string;
            earns?: WorkloadEarns;
            resource: string;
        }

        // A refusal: error.code is the server's code, such as "noAccess", "notYourWorkload", "overAllocated",
        // "unknownWorkload", "rateLimited" or "notFound"
        interface Error extends globalThis.Error {
            code: string;
        }

        interface Api {
            list(): Promise<List>;
            get(rackId: number): Promise<Detail>;
            workloads(): Promise<WorkloadInfo[]>;
            // Only for a workload the page's own resource registered
            setShare(rackId: number, workloadId: string, share: number): Promise<true>;
            setPower(rackId: number, on: boolean): Promise<true>;
            setProfile(rackId: number, profile: string): Promise<true>;
        }
    }

    interface PaymentResult {
        paymentId: string;
        status: "settled";
        method: "bank" | "crypto";
        // Dollars
        amount: number;
        coin?: string;
    }

    interface StorageChange {
        key: string;
        // null when it was removed
        value: unknown;
    }

    // Kept by the server per account and app or site, the same on every laptop the account signs in to. Needs a
    // registration with a storage field
    interface StorageApi {
        get<T = unknown>(key: string): Promise<T | null>;
        getAll(): Promise<Record<string, unknown>>;
        // null removes the key
        set(key: string, value: unknown): Promise<true>;
        remove(key: string): Promise<true>;
        keys(): Promise<string[]>;
        usage(): Promise<{ bytes: number; maxBytes: number }>;
    }

    interface CastScreen {
        id: string;
        label: string;
        via: "hdmi" | "wireless";
        // Metres
        distance: number;
        busy: boolean;
    }

    interface CastEvent {
        state: "started" | "stopped" | "wantSnapshot";
        screen?: string;
    }

    // Shows the app's own viewer page on a world screen. Needs a cast field in RegisterApp naming the
    // viewer page, which loads laptop-cast.js
    interface CastApi {
        screens(): Promise<CastScreen[]>;
        // Shows the OS's Cast menu; the player picks the screen
        start(snapshot: unknown): Promise<{ screen: string; via: "hdmi" | "wireless" }>;
        // Replaces what the viewer shows; rejects with "tooLarge" over the cast's size limit
        snapshot(content: unknown): Promise<true>;
        delta(delta: unknown): Promise<true>;
        signal(signal: unknown): Promise<true>;
        stop(): Promise<true>;
    }

    interface RoomMember {
        // Random for each room, never a server id
        id: string;
        // What the resource's join check gave this member, such as a name
        data?: unknown;
    }

    interface RoomEvents {
        message: { from: string; data: unknown };
        join: RoomMember;
        leave: RoomMember;
        // "left", "kicked", "closed", "offline", "laptopOff"
        close: { reason: string };
    }

    interface Room {
        readonly id: string;
        readonly name: string;
        // This page's member id
        readonly self: string;
        // Kept current by the SDK
        readonly members: RoomMember[];
        // to: one member's id, everyone else when left out. Rejects with rateLimited over the room's rate
        send(data: unknown, to?: string): Promise<true>;
        leave(): Promise<true>;
        on<E extends keyof RoomEvents>(event: E, handler: (data: RoomEvents[E]) => void): () => void;
    }

    // Realtime rooms with pages of the same app or site on other laptops. Needs a rooms field in the registration
    interface RoomsApi {
        // name: letters, digits, _ and -, up to 48
        join(name: string, data?: unknown): Promise<Room>;
    }

    interface ShareOptions {
        title?: string;
        text?: string;
        url?: string;
        // With a file only Mail is offered
        file?: FileHandle | string;
    }

    type Permission = "account" | "clipboard" | "job" | "notifications";

    interface PermissionsApi {
        // What the player granted this app, false for undecided
        get(): Promise<Record<Permission, boolean>>;
    }

    interface Sdk {
        readonly version: number;
        // Resource that owns the page, null in a normal browser
        readonly resource: string | null;
        readonly inGame: boolean;
        // Running inside the laptop's iframe rather than opened on its own
        readonly embedded: boolean;
        readonly context: Context | null;
        ready(callback?: (context: Context) => void): Promise<Context>;
        // POSTs to the resource's RegisterNUICallback(endpoint) and parses the JSON reply
        post<T = unknown>(endpoint: string, data?: unknown): Promise<T>;
        // Answers post(endpoint) while the page runs in a normal browser, ignored in game
        mock(endpoint: string, handler: (data: unknown) => unknown): Sdk;
        // Answers { id }: the id given, or one the OS made
        notify(options: NotifyOptions | string): Promise<{ id: string }>;
        can(capability: Capability): boolean;
        readonly files: FilesApi;
        account(): Promise<Account>;
        // Apps only, 0 hides it
        badge(count: number): Promise<true>;
        readonly clipboard: ClipboardApi;
        readonly sound: SoundApi;
        // The payment id comes from your resource's server, which made it with CreatePayment
        pay(paymentId: string): Promise<PaymentResult>;
        readonly storage: StorageApi;
        readonly cast: CastApi;
        readonly rooms: RoomsApi;
        // Shows the OS's Share sheet; rejects with "cancelled" when the player closes it
        share(options: ShareOptions): Promise<{ target: "mail" | "messenger" | "chat" | "files" | "clipboard" }>;
        readonly permissions: PermissionsApi;
        close(): Promise<true>;
        setTitle(title: string): Promise<true>;
        // Opens the address in the OS's browser: Ledge, Emberfox or Veil Browser. From an app it resolves with the
        // browser's window, from a site with true
        openUrl(url: string, options?: OpenUrlOptions): Promise<{ windowId: string } | true>;
        // Sites only: moves the tab to another of the site's addresses without loading the page again, like
        // history.pushState. Resolved against the current address, such as "/units/12"; rejects for another site
        pushUrl(url: string, options?: PushUrlOptions): Promise<true>;
        // Rejects when the app doesn't exist or doesn't run on this OS. Without params an app that is already open keeps
        // the ones it has
        openApp(appId: string, params?: Record<string, unknown>): Promise<{ windowId: string }>;
        getContext(): Promise<Context>;
        // Keeps a JSON value of 16 KiB at most for the app's window or the address the site's tab shows, given back in
        // context.state when the laptop wakes from being closed, put away, a relog or a server restart; null forgets it
        saveState(state: unknown): Promise<true>;
        // Returns a function that stops listening
        on<E extends EventName>(event: E, handler: (data: Events[E]) => void): () => void;
        off<E extends EventName>(event: E, handler: (data: Events[E]) => void): void;
        // The player's laptop racks; changes are not pushed, read them again with get
        readonly racks: Racks.Api;
    }
}

interface Window {
    Laptop: ZykeLaptop.Sdk;
}

declare var Laptop: ZykeLaptop.Sdk;

declare namespace ZykeLaptopCast {
    interface Context {
        locale: string;
        // Pixels of the screen's picture
        width: number;
        height: number;
    }

    interface Events {
        setup: Context;
        snapshot: unknown;
        delta: unknown;
        signal: unknown;
    }

    interface Api {
        readonly context: Context | null;
        on<E extends keyof Events>(event: E, handler: (data: Events[E]) => void): () => void;
    }
}

declare var LaptopCast: ZykeLaptopCast.Api;
