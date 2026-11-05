return {
    ["app:name"] = "My Tools",
    ["app:description"] = "A starting point for your own Terminal commands. Type help in a Terminal to see them.",

    -- greet, the server command
    ["greet:usage"] = "greet [name]",
    ["greet:description"] = "Say hello from the server",
    ["greet:askName"] = "Your name: ",
    ["greet:noName"] = "A greeting needs a name.",
    ["greet:askStyle"] = "How should it sound?",
    ["greet:style:friendly"] = "Friendly",
    ["greet:style:formal"] = "Formal",
    ["greet:style:formalHint"] = "for the boss",
    ["greet:style:secret"] = "Secret handshake",
    ["greet:style:secretHint"] = "members only",
    ["greet:preparing"] = "Warming up",
    ["greet:friendly"] = "Hey %s, good to see you!",
    ["greet:formal"] = "Good day, %s.",
    ["greet:people"] = "%s people are in the city right now.",
    ["greet:shout"] = "Shout it too?",

    -- stopwatch, the program
    ["stopwatch:description"] = "A stopwatch on the whole Terminal",
    ["stopwatch:title"] = "STOPWATCH",
    ["stopwatch:keys"] = "Space starts and stops, L marks a lap, R resets, Q quits",
    ["stopwatch:running"] = "running",
    ["stopwatch:stopped"] = "stopped",
    ["stopwatch:lap"] = "Lap %s",
    ["stopwatch:result"] = "Stopped at %s",
    ["stopwatch:notTerminal"] = "Type stopwatch in a Terminal to run this page.",
}