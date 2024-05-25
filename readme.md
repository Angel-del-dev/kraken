# Information

* Improved version of [Simple web crawler](https://github.com/Angel-del-dev/Simple-web-crawler)

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
  "exit_domain": true, // If set to true, it allows kraken to move between other websites
  "exclude_domains": [],
  "time_sleep": 0.2, // Time between requests(Does not include the time of parsing HTML)
  "output": "links.l", // File where the links are going to be stored
  "debug": true // Prints to console every link found
}
````

# TODO

* Stats program
  * Amount of the same url grouped by domain