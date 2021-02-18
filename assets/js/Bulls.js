import React, { useState, useEffect } from 'react';
import {ch_push, ch_join, ch_reset} from './socket';

import { Table, TableHead, 
    TableBody, TableRow, TableCell, 
    Button, Paper, TableContainer, 
    TextField, Grid, Typography} from "@material-ui/core";


// Return the reset screen
function Finished({message, reset}) {
    return (
        <div className="App" style={{padding: 20, width: "100%"}}>
            <Typography variant="h3">{message}</Typography>
            <p>
                <Button onClick={reset} variant="contained" color="primary">
                    Reset
                </Button>
            </p>
        </div>
    );
}


function Display({guesses}) {
    return (<Grid item xs={12}> <TableContainer component={Paper}> <Table>
        <TableHead color="primary">
            <TableRow>
                <TableCell width="60%"> 
                    <Typography variant="h6"> Guess </Typography> 
                </TableCell>
                <TableCell align="center"> 
                    <Typography variant="h6"> Bulls </Typography> 
                </TableCell>
                <TableCell align="center"> 
                    <Typography variant="h6"> Cows </Typography> 
                </TableCell>
            </TableRow>
        </TableHead>
        <TableBody>
            {guesses.map(guess =>
            <TableRow>
                <TableCell>{guess.guess}</TableCell>
                <TableCell align="center">{guess.bulls}</TableCell>
                <TableCell align="center">{guess.cows}</TableCell>
            </TableRow>)}
        </TableBody>
    </Table> </TableContainer> </Grid>)
}

function Controls({guess, reset, setError}) {
    // The text in the guess field
    const [text, setText] = useState("");
    // Updates the text with the new value, and does some validation
    function updateText(ev) {
        setError({error: false, message:""});
        let val = ev.target.value;
        setText(val);
    }

    function myGuess() {
        guess(text);
        setText("");
    }
    // Handles the enter keypress to guess
    function keyPress(ev) {
        if (ev.key === "Enter") {
            myGuess()
        }
    }

    return(<Grid container alignItems="flex-start" >
        <Grid item xs={8}>
            <TextField id="outlined-basic" 
                label="Guess" 
                size="small"
                variant="outlined" 
                value={text}
                onChange={updateText}
                onKeyPress={keyPress} />
            <Button onClick={myGuess} variant="contained" color="primary">
                Guess
            </Button>
        </Grid>
        <Grid item xs={4}>
            <Button onClick={reset} variant="contained" color="primary">
                Reset
            </Button>
        </Grid>
    </Grid>)
}

export default function Bulls() {
    // The game state: contains the secret and the guesses
    const [state, setState] = useState({gameOver: false, guesses: []});
    // The error object
    const [error, setError] = useState({error: false, message: "" });

    useEffect(() => {
        ch_join(setState);
    });

    let main = null;
    if (state.game_over)  {
        main = (<Finished message={state.message} reset={ch_reset} />)
    } else {
        main = (<div style={{ width: "100%"}}>
                <Controls setError={setError} guess={ch_push} reset={ch_reset} />
                <Display guesses={state.guesses} />
        </div>);

    }
    // The standard game screen
    return (
        <div className="App" style={{ padding: 20 }}>
            <Grid container spacing={2} alignItems="flex-start">
                <Grid item style={{paddingBottom: 40}} xs={12}>
                    <Typography variant="h3"> Bulls&Cows </Typography>
                </Grid>
                {main}
            </Grid>
        </div>
    );
}

