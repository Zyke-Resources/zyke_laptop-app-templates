// Tic-tac-toe between two laptops. Both players join the same room with Laptop.rooms; each move is a room message the
// other page applies. The scoreboard can be cast to a screen in the world with Laptop.cast, and server.lua checks every
// snapshot before a screen shows it
import "./mock.js";

const Laptop = window.Laptop;
const lines = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]];
const boardEl = document.getElementById("board");
const castButton = document.getElementById("cast");
let strings = {};
let room = null;
// This page's mark: the member with the lower id plays X, so both pages agree without asking anyone
let mark = null;
let board = Array(9).fill("");
let round = 0;
let score = { X: 0, O: 0, draws: 0 };
let casting = false;

const t = (key, ...values) => values.reduce((text, value) => text.replace("%s", value), strings[key] ?? key);

const translate = () => {
    document.querySelectorAll("[data-text]").forEach((el) => (el.textContent = t(el.dataset.text)));
    document.querySelectorAll("[data-placeholder]").forEach((el) => (el.placeholder = t(el.dataset.placeholder)));
};

const other = (value) => (value === "X" ? "O" : "X");

// X starts the first round, then the players take turns starting
const turn = () => {
    const moves = board.filter(Boolean).length;
    const starter = round % 2 === 0 ? "X" : "O";

    return moves % 2 === 0 ? starter : other(starter);
};

const winner = () => {
    const line = lines.find(([a, b, c]) => board[a] && board[a] === board[b] && board[a] === board[c]);

    if (line) return board[line[0]];

    return board.every(Boolean) ? "draw" : null;
};

const opponent = () => room?.members.find((member) => member.id !== room.self);

// data is what server.lua's join check gave the member, its character's first name
const playerName = (value) => room?.members.find((member) => (member.id === room.self) === (value === mark))?.data?.name ?? "?";

const nameOf = (value) => (value === mark ? t("game:you") : playerName(value));

// Plain values only: server.lua checks and copies them, and adds the text the screen shows
const snapshot = () => ({
    players: [playerName("X"), playerName("O")],
    wins: [score.X, score.O],
    draws: score.draws,
    board: board.map((cell) => cell || ".").join(""),
    turn: winner() ? null : turn(),
});

const sendCast = () => casting && Laptop.cast.snapshot(snapshot()).catch(() => {});

const status = () => {
    const result = winner();

    if (!opponent()) return t("game:waiting");
    if (result === "draw") return t("game:draw");
    if (result) return result === mark ? t("game:won") : t("game:lost", nameOf(result));

    return turn() === mark ? t("game:yourTurn") : t("game:theirTurn", nameOf(turn()));
};

const render = () => {
    const playing = !!opponent() && !winner() && turn() === mark;

    boardEl.querySelectorAll(".cell").forEach((cell, index) => {
        cell.textContent = board[index];
        cell.className = `cell${board[index] ? ` is-${board[index].toLowerCase()}` : ""}`;
        cell.disabled = !playing || !!board[index];
    });

    document.getElementById("player-x").textContent = `X  ${nameOf("X")}`;
    document.getElementById("player-o").textContent = `${nameOf("O")}  O`;
    document.getElementById("score").textContent = `${score.X} - ${score.O}`;
    document.getElementById("status").textContent = status();
    document.getElementById("again").hidden = !winner();
    castButton.hidden = !Laptop.can("cast");
    castButton.textContent = t(casting ? "cast:stop" : "cast:start");
    sendCast();
};

const finishRound = () => {
    const result = winner();

    if (result === "draw") score.draws += 1;
    else if (result) score[result] += 1;
};

// A move from either player, applied the same way on both pages
const play = (value, index) => {
    if (winner() || board[index] || turn() !== value) return false;

    board[index] = value;
    finishRound();
    render();

    return true;
};

const newRound = () => {
    board = Array(9).fill("");
    round += 1;
    render();
};

// A new opponent starts a new match
const resetMatch = () => {
    const ids = room.members.map((member) => member.id).sort();

    mark = ids.indexOf(room.self) === 0 ? "X" : "O";
    board = Array(9).fill("");
    round = 0;
    score = { X: 0, O: 0, draws: 0 };
    render();
};

const showLobby = (errorKey) => {
    room = null;
    document.getElementById("game").hidden = true;
    document.getElementById("lobby").hidden = false;
    document.getElementById("lobby-error").hidden = !errorKey;
    document.getElementById("lobby-error").textContent = errorKey ? t(errorKey) : "";
};

const join = async (event) => {
    event.preventDefault();

    const name = document.getElementById("table").value.trim();
    const button = document.getElementById("join");

    button.disabled = true;
    button.textContent = t("lobby:joining");

    try {
        room = await Laptop.rooms.join(name);
    } catch (error) {
        const known = ["invalid", "quota", "offline"].includes(error.code);

        showLobby(known ? `error:${error.code}` : "error:failed");

        return;
    } finally {
        button.disabled = false;
        button.textContent = t("lobby:join");
    }

    room.on("join", resetMatch);
    room.on("leave", resetMatch);
    room.on("close", ({ reason }) => showLobby(reason === "left" ? null : "error:closed"));
    room.on("message", ({ from, data }) => {
        if (from === room.self || !opponent()) return;
        if (data?.type === "move" && Number.isInteger(data.cell)) play(other(mark), data.cell);
        if (data?.type === "again" && winner()) newRound();
    });

    document.getElementById("lobby").hidden = true;
    document.getElementById("game").hidden = false;
    document.getElementById("table-name").textContent = t("game:table", room.name);
    resetMatch();
};

const toggleCast = async () => {
    try {
        // start shows the OS's Cast menu, the player picks the screen
        if (casting) await Laptop.cast.stop();
        else await Laptop.cast.start(snapshot());

        casting = !casting;
    } catch (error) {
        if (error.code !== "cancelled") console.error(error);
    }

    render();
};

for (let index = 0; index < 9; index++) {
    const cell = document.createElement("button");

    cell.type = "button";
    cell.className = "cell";
    cell.addEventListener("click", () => play(mark, index) && room.send({ type: "move", cell: index }).catch(() => {}));
    boardEl.append(cell);
}

document.getElementById("lobby").addEventListener("submit", join);
document.getElementById("leave").addEventListener("click", () => room?.leave().catch(() => {}).then(() => showLobby(null)));
document.getElementById("again").addEventListener("click", () => {
    newRound();
    room.send({ type: "again" }).catch(() => {});
});
castButton.addEventListener("click", toggleCast);

// The screen went away or asks for the whole picture again, such as when someone walks up to it
Laptop.on("cast", (event) => {
    if (event.state === "stopped") casting = false;
    if (event.state === "wantSnapshot") casting = true;
    if (room) render();
});

Laptop.ready().then(async () => {
    strings = (await Laptop.post("Setup")).strings;
    translate();
    document.getElementById("table").value = `table-${Math.floor(Math.random() * 900 + 100)}`;
    document.body.classList.remove("is-loading");
});
