# Vimxp
Vimxp provides a http server that allows you to extract text by vim commands.

## Demo
TODO

## Usage
1. Open main.lua and run the following command.
    ```vim
    :luafile %
    ```
1. Then visit http://localhost:12345/vimxp/api/v1/extract/

## Example
```bash
curl -X POST http://localhost:12345/vimxp/api/v1/extract/ --json '{"texts": ["hello, (Vimxp)!"], "commands": ["yi)"], "registers": ["0"]}'
```
