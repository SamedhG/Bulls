
// Returns a random 4 unique digit string
export function generateSecret() {
    let s = new Set();
    while(s.size < 4) {
        s.add(Math.floor(Math.random()*10))
    }
    return [...s].join('')
}

// Scores the given guess returning an object with the guess and its score
export function score(guess, secret) {
    console.assert(guess.length === secret.length)
    let bulls = guess.split('').filter((x, i) => secret[i] === x).length;
    let cows = guess.split('').filter((x) => secret.includes(x)).length - bulls;
    return { guess, bulls, cows };
}
