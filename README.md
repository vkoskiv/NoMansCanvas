<p align="center">
    <a href="LICENSE">
        <img src="http://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-3.1-brightgreen.svg" alt="Swift 3.1">
    </a>
</center>

## Synopsis

No Man's Canvas is a Jyväskylä University project to recreate Reddit's /r/place concept in a smaller scale.

## Installation

git clone https://github.com/vkoskiv/NoMansCanvas

cd NoMansCanvas

vapor build

vapor run serve

This deploys by default on localhost:8080, configurable in Config/server.json

# Dependencies

The React-based web client can be found [here](https://github.com/EliasHaaralahti/No-Mans-Canvas-Client)

This project requires the [Vapor 2](https://vapor.codes) framework, and [Swift 3.1](https://swift.org)

You also need a `mysql` db, and the `cmysql` library installed. Configure in Config/mysql.json

For debugging, you could also switch to an in-memory DB, but I don't think the current schema supports it.

*Caveat:* This backend was originally built in 2017, the Vapor 2 toolchain is no longer supported and may not work without some work. YMMV.

## Authors

- Valtteri Koskivuori [(vkoskiv)](https://github.com/vkoskiv)
- Mikael Myyrä [(MoleTrooper)](https://github.com/MoleTrooper)
- Elias Haaralahti [(EliasHaaralahti)](https://github.com/EliasHaaralahti)
- Jonni Pitkänen [(JonniP)](https://github.com/JonniP)
