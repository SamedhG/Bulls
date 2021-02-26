#!/bin/bash
# deploy script adapted from class notes
export MIX_ENV=prod
export SECRET_KEY_BASE=insecure
export PORT=4810

mix deps.get --only prod
mix compile


KEY=`pwd`/.base

if [ ! -e "$KEY" ]; then
    mix phx.gen.secret > "$KEY"
fi

SECRET_KEY_BASE=$(cat "$KEY")
export SECRET_KEY_BASE

npm install --prefix ./assets
npm run deploy --prefix ./assets
mix phx.digest

mix release
