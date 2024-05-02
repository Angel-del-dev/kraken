module main

import structs { Links, Config }
import net.http
import net.html
import os
import json
import time

fn get_links(mut links Links, url string, domain string) {
	contents := http.get(url) or {
		panic('Error parsing <<$url>>')
	}

	dom := html.parse(contents.str())

	a_tags := dom.get_tags(name: 'a')

	for a in a_tags {
		link := a.attributes['href'].str()

		if ['.', '#',''].contains(link) || !link.contains('://') { continue }
		n_domain, new_url := format_url(domain, link)

		if links.links[n_domain].contains(new_url) { continue }
		links.links[n_domain] << new_url
	}

}

fn format_url(current_domain string, url string) (string, string) {
	url_split := url.split('')
	mut n_url := url.clone()
	if url_split[0] == '.' {
		n_url = url.substr(1, url.len)
	}
	if n_url.split('')[0] == '/' {
		return current_domain, n_url
	}

	splitted := n_url.split('://')
	protocol := splitted[0]+'://'

	mut separated := splitted[1].split('/')

	domain := separated[0]
	separated.delete(0)

	new_url := '/'+separated.join('/')
	return protocol+domain, new_url
}

fn get_next_domain(mut links Links, active string) string {
	keys := links.links.keys()
	c_index := keys.index(active)
	if c_index + 1 >= keys.len { return '' }

	return keys[c_index+1]
}

fn seconds_to_nano_milliseconds(seconds f32) f32 {
	return seconds * 1_000
}

fn loop(configure Config, mut links Links, ac_domain string, index int) {
	time.sleep(seconds_to_nano_milliseconds(configure.time_sleep))

	if index >= links.links[ac_domain].len || configure.exclude_domains.contains(ac_domain) {
		if !configure.exit_domain { return }
		new_domain := get_next_domain(mut links, ac_domain)

		if new_domain == '' { return }
		loop(
			configure,
			mut links,
			new_domain,
			0
		)
		return
	}

	url := ac_domain+links.links[ac_domain][index]
	if configure.debug { print("$url\n") }
	get_links(mut links, url, ac_domain)
	loop(configure, mut links, ac_domain, index + 1)
}

fn read_config(file string) Config {
	conf_str := os.read_file(file) or {
		panic('File <<$file>> could not be found')
	}
	c := json.decode(Config, conf_str) or {
		panic('Invalid configuration')
	}
	return c
}

fn save_to_file(configuration Config, lin Links) {
	f_json := json.encode(lin)
	file := configuration.output
	os.write_file(file, f_json) or {
		panic('Could not create file <<$file>>')
	}
}

fn main() {
	conf_file := os.args[1]
	con := read_config(conf_file)

	mut v_links := Links{}

	mut domain, link := format_url('', con.url)

	v_links.add(link, domain)

	loop(con, mut v_links, domain, 0)

	save_to_file(con, v_links)
}