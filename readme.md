# Execute the crawler

## Notation

````bash
'exefile'.exe 'path_to_config.json'
````

## Example
````bash
kraken.exe config.json
````

## Config.json

````json
{
  "url": "",
  "exit_domain": true,
  "exclude_domains": [],
  "time_sleep": 0.2,
  "output": "links.l",
  "debug": true
}
````