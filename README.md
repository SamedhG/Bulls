# Bulls

## Introduction 

This is a server implementation of the bulls&cows game.  
 - The client connects and joins on the socket "game:1"
 - The server generates and stores a random secret.
 - The client sends a guess to the server and then the server tells the client
   what the game state should be
 - The client can send a reset message to generate a new secret and clear all
   the guesses


## Data definition
A Guess is sent by the client and is a string  

An `:ok` Guess reply is one of:
 - `{game_over: false, guesses: [] }`
 - `{game_over: true, message: "Some string"}`  

An `:error` guess reply is a `{message: ""}`

A Reset message has no payload
A reset reply should always be `{game_over: false, guesses: [] }`

## Running
To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


