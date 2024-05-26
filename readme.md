# Information

* Improved version of [Simple web crawler](https://github.com/Angel-del-dev/Simple-web-crawler)
* Contains [KrakenScript](./krakenscript.md), a simple interpreted language to scrap websites while crawling

# Execute the crawler

## Notation

````bash
./kraken 'path_to_config.json'
````

## Config.json

````json
{
  "url": "", 
  "exit_domain": true, // If set to true, it allows kraken to move between other websites
  "exclude_domains": [],
  "time_sleep": 0.2, // Time between requests(Does not include the time of parsing HTML)
  "output": "links.l", // File where the links are going to be stored
  "debug": true // Prints to console every link found,
  "save_every_level_change": false, // Saves to the file every time the domain, subdomain or extension changes
  "amount_of_lines_before_save": 10, // Saves every n amount of urls scanned
  "run": 'run.ks' // Executes a KrakenScript
}
````

# TODO

* Stats program
  * Amount of the same url grouped by domain
