import React, { useState, useEffect } from 'react';
import {ch_guess, ch_login, ch_setup, ch_reset, ch_ready} from './socket';

import { Table, TableHead, 
    TableBody, TableRow, TableCell, 
    Button, Paper, TableContainer, 
    TextField, Grid, Typography, Snackbar,
    Radio, RadioGroup, FormControlLabel, Box, Divider
    } from "@material-ui/core";
import { makeStyles } from '@material-ui/core/styles';

// Return the reset screen
function Finished({message}) {
    return (
        <div className="App" style={{padding: 20, width: "100%"}}>
            <Typography variant="h3">{message}</Typography>
            <p>
                <Button onClick={ch_reset} variant="contained" color="primary">
                    Reset
                </Button>
            </p>
        </div>
    );
}


function Display({guesses}) {

    function one_round(guesses, n) {
        return(
        <TableBody>
            <TableRow key={`title${n}`}>
                <TableCell colSpan={4}> Round: {n} </TableCell>
            </TableRow>
            { Object.keys(guesses).map(
                (name, m) => (
                    <TableRow key={`row${n}_${m}`}>
                        <TableCell>{name}</TableCell>
                        <TableCell>{guesses[name].guess}</TableCell>
                        <TableCell align="center">{guesses[name].bulls}</TableCell>
                        <TableCell align="center">{guesses[name].cows}</TableCell>
                    </TableRow>))
            }
        </TableBody>)

    }

    return (<Grid item xs={12}> <TableContainer component={Paper}> <Table>
        <TableHead color="primary">
            <TableRow>
                <TableCell> 
                    <Typography variant="h6"> User </Typography> 
                </TableCell>
                <TableCell> 
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
        {guesses.map((x, n) => one_round(x, guesses.length - n))}
        </Table> </TableContainer> </Grid>)
}

function Controls({guess, reset, error, setError}) {
    // The text in the guess field
    const [text, setText] = useState("");
    const [curr_guess, setGuess] = useState("");
    const [seconds, setSeconds] = useState(30);


    useEffect(() => {
        let interval = setInterval(() => {
            if(seconds == 1){
                setSeconds(30);
            } else {
                setSeconds(seconds => seconds - 1);
            }
        }, 1000);
        return () => clearInterval(interval);
    }, [seconds]);

    const classes = makeStyles((theme) => ({
        root: {
            '& .MuiTextField-root': {
                margin: theme.spacing(1),
                width: '25ch',
            },
            '& .MuiButton-root': {
                margin: theme.spacing(1),
            },
           '& .MuiTypography-root': {
                margin: theme.spacing(1),
            },
        },
    }))();

    // Updates the text with the new value, and does some validation
    function updateText(ev) {
        setError({error: false, message:""});
        let val = ev.target.value;
        setText(val);
    }

    function myGuess() {
        guess(text);
        if (!error.error) setGuess(text)
        setText("");
    }
    // Handles the enter keypress to guess
    function keyPress(ev) {
        if (ev.key === "Enter") {
            myGuess()
        }
    }

    return(<Grid container alignItems="flex-start" className={classes.root}>
        <Grid item xs={4}>
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
        <Grid item xs={2}>
            <Typography>
                Current Guess: {curr_guess}
            </Typography>
        </Grid>
        <Grid item xs={2}>
            <Typography>
                Time Remaining: {seconds}s
            </Typography>
        </Grid>
        <Grid item xs={4}>
            <Button onClick={reset} variant="contained" color="primary">
                Reset
            </Button>
        </Grid>
    </Grid>)
}

function Login({setLogin}) {
    const [user, setUser] = useState("");
    const [game, setGame] = useState("");
    const [observer, setObserver] = useState(false);

    const classes = makeStyles((theme) => ({
        root: {
            'display': 'flex',
            'margin': 'auto',
            '& .MuiTextField-root': {
                margin: theme.spacing(1),
                width: '25ch',
            },
        },
    }))();
    function login() {
        ch_login(game, user, observer, setLogin)
    }
    return(
        <div style={{display: 'fixed'}}>
            <div className={classes.root}>
                <TextField label="User Name" size="small" 
                    variant="outlined" value={user} 
                    onChange={(x) => setUser(x.target.value)} />
                <TextField label="Game Name" size="small" 
                    variant="outlined" value={game} 
                    onChange={(x) => setGame(x.target.value)} />
            </div>
            <div className={classes.root}>
                <br />
                <RadioGroup row value={observer} onChange={(e) => {console.log(e); setObserver(e.target.value === "true")}} style={{margin:"auto"}}>
                    <FormControlLabel value={true} control={<Radio />} label="Observer" />
                    <FormControlLabel value={false} control={<Radio />} label="Player" />
                </RadioGroup>
            </div>
            <div className={classes.root}>
                <Button onClick={login} variant="contained" color="primary" >Login</Button>
            </div>
        </ div>)
}

function Waiting({players}) {
    return (
        <Grid item xs={12}> 
            <Button onClick={ch_ready} variant="contained" color="primary">Ready</Button>
            <TableContainer component={Paper}> 
                <Table>
                    <TableHead color="primary">
                        <TableRow>
                            <TableCell width="60%"> 
                                <Typography variant="h6"> User </Typography> 
                            </TableCell>
                            <TableCell align="center"> 
                            </TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {Object.keys(players).map((user, n) =>
                        <TableRow key={`p${n}`}>
                            <TableCell>{user}</TableCell>
                            <TableCell align="center">{players[user] ?  "ready" : "not ready" }</TableCell>
                        </TableRow>)}
                    </TableBody>
                </Table> </TableContainer> 
        </Grid>)
}


function Bulls() {

    // The game state: contains the secret and the guesses
    const [state, setState] = useState({state: "waiting", players: {}, user: ""});
    // The error object
    const [error, setError] = useState({error: false, message: "" });
    // Manages the login state on the channel
    const [login, setLogin] = useState(false)

    useEffect(() => {
        ch_setup(setState, setError);
    });

    let main = null;
    if (!login) {
        main = <Login setLogin={setLogin}/>
    }
    else if (state.state == "waiting")  {
        main = (<Waiting players={state.players} />)
    } else {
        main = (<div style={{ width: "100%"}}>
            <Controls setError={setError} guess={ch_guess} reset={ch_reset} error={error} />
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
                <Grid container alignItems="center" style={{padding: 10}} spacing={2}>
                    <Grid item xs> UserName: {state.user} </ Grid> 
                    <Divider orientation="vertical" flexItem />
                    <Grid item xs> GameName: {state.name}</ Grid> 
                    <Divider orientation="vertical" flexItem />
                    <Grid item xs> Wins: {state.wins || 0}</ Grid> 
                    <Divider orientation="vertical" flexItem />
                    <Grid item xs> Loses: {state.loses || 0}</ Grid> 
                </Grid>
                {main}
                <Snackbar open={error.error} message={error.message} />
            </Grid>
        </div>
    );
}

export default Bulls;
