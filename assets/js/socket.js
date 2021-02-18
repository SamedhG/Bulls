// Pulled from Class Notes

import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: ""}})
socket.connect()

let channel = socket.channel("game:1", {});

let state = {
    game_over: false,
    guesses: [],
};
let error = {
    error: false,
    message: ""
};

let callback = null;
let setError = null;

function state_update(st) {
    state = st;
    if (callback) callback(st);
    error = {error: false, message: ""}
    if(setError) setError(error);
}

function set_error(e) {
    error = {error: true, message: e.message}
    if(setError) setError(error);
}

export function ch_join(cb, err) {

    callback = cb;
    setError = err;
    callback(state);
    setError(error);
}

export function ch_push(guess) {
    channel.push("guess", guess)
        .receive("ok", state_update)
        .receive("error", set_error);
}

export function ch_reset() {
    channel.push("reset", {})
        .receive("ok", state_update)
        .receive("error", resp => { console.log("Unable to reset", resp) });
}

channel.join()
    .receive("ok", state_update)
    .receive("error", resp => { console.log("Unable to join", resp) });
