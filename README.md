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
#### Game State: 
```
{ 
    state: :waiting,  
    players: {name: ready?}, 
    scoreboard: {name : {wins, losses} } 
}
```

```
{ 
    state: :ongoing, 
    secret: "some secret", 
    guesses: [[]], 
    players: [],
    current_guesses: []
    scoreboard: {name : {wins, losses} } 
}
```

```
{ 
    state: :game_over,
    players: {name: win?},
    scoreboard: {name : {wins, losses} } 
}
```

#### Game View

Get the current view in the following format:
```
%{ state: "waiting", players: ready_map, scoreboard }
```

```
%{ state: "ongoing", guesses: guess_table, scoreboard }
```


```
%{ state: "game_over", players: results_map, scoreboard }
```

Where 
 - a ready_map is a map from players to ready? bools
 - a guess_table is a list of maps of players to that rounds score
 - a results map is a map from players to win? bools
## Running
To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


