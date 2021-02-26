// Pulled from Class Notes

import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: ""}})
socket.connect()

let channel = socket.channel("game:1", {});
let setState = null;
let setError = null;
let error = { error: false, message: "" }
let state = { state: "waiting", players: {}, user: "", name: "", scoreboard: {}}


function state_update(st) {
    console.log("setting state to: ", st)
    state = st
    if (setState) setState(st);
    error = {error: false, message: ""}
    if(setError) setError(error);
}

function set_error(e) {
    error = {error: true, message: e.message}
    if(setError) setError(error);
}

export function ch_setup(cb, err) {
    setState = cb;
    setError = err;
}

export function ch_login(name, user, observer, setLogin) {
    channel.push("login", {name, user, observer})
        .receive("ok", (st) => { state_update(st); setLogin(true) })
        .receive("error", set_error);
}

export function ch_guess(guess) {
    channel.push("guess", guess)
        .receive("ok", state_update)
        .receive("error", set_error);
}

export function ch_ready() {
    channel.push("ready", {})
        .receive("ok", state_update)
        .receive("error", set_error);
}

export function ch_reset() {
    channel.push("reset", {})
        .receive("ok", state_update)
        .receive("error", resp => { console.log("Unable to reset", resp) });
}

channel.join()
    .receive("ok", () => console.log("Joined Channel"))
    .receive("error", resp => { console.log("Unable to join", resp) });

channel.on("view", state_update)
