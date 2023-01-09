# Zane

> Zane is a simple discord for for playing simple games in a discord chat, it features communautary features such as rivals, battles and leaderboard to spice up your friends servers!

## Structure

Zane is based on [Nova](https://github.com/discordnova/nova) and features a distributed architecture.

| Component    | Description                                         | Language   |
|--------------|-----------------------------------------------------|------------|
| zane-worker  | Dispatch game events and process interaction events | TypeScript |
| game-manager | Stores the games states and hangle gameplay events  | Rust       |

Each game is developped with [Trzl](https://github.com/teal-language/tl) and is run wihin a sandbox in game-manager.