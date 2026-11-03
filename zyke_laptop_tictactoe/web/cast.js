// The page a world screen shows while the app casts. Every player who looks at the screen runs it, so it only draws
// when a snapshot arrives: no timers, animations or requests. Its text comes in the snapshot from server.lua
const cells = [];
const boardEl = document.getElementById("board");

for (let index = 0; index < 9; index++) {
    const cell = document.createElement("div");

    cell.className = "cell";
    boardEl.append(cell);
    cells.push(cell);
}

const render = (snapshot) => {
    const { labels } = snapshot;

    document.querySelector(".scoreboard").hidden = false;
    document.getElementById("title").textContent = labels.title;
    document.getElementById("name-x").textContent = snapshot.players[0];
    document.getElementById("name-o").textContent = snapshot.players[1];
    document.getElementById("wins-x").textContent = `${labels.wins} ${snapshot.wins[0]}`;
    document.getElementById("wins-o").textContent = `${labels.wins} ${snapshot.wins[1]}`;
    document.getElementById("footer").textContent = snapshot.turn ? `${labels.draws} ${snapshot.draws} · ${labels.turn} ${snapshot.turn}` : `${labels.draws} ${snapshot.draws}`;

    cells.forEach((cell, index) => {
        const value = snapshot.board[index];

        cell.textContent = value === "." ? "" : value;
        cell.className = `cell${value === "." ? "" : ` is-${value.toLowerCase()}`}`;
    });
};

// Outside the game the viewer SDK is missing; nothing to draw then
if (window.LaptopCast) window.LaptopCast.on("snapshot", render);
