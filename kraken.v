module main

import structs { Links, Config }
import net.http
import net.html
import os
import json
import time

fn get_links(mut links Links, url string, domain string, configuration Config) {
	contents := http.get(url) or {
		print("Saving because of error encounted\n")
		save_to_file(configuration, links)
		panic('Error parsing <<$url>>')
	}

	dom := html.parse(contents.str())

	a_tags := dom.get_tags(name: 'a')
	if configuration.debug { print("Urls found: "+a_tags.len.str()+"\n") }
	for a in a_tags {
		link := a.attributes['href'].str()
		if link.replace(' ', '').len == 0 { continue }
		if link.contains_any_substr(['#',' ', 'javascript', 'mailto:']) { continue }

		n_domain, new_url := format_url(domain, link)

		if new_url.len >= 2 && new_url.substr(0, 2) == '//'{
			new_domain := n_domain.split('://')[0]+'://'

			if links.links[new_domain].contains(new_url) { continue }
			links.links[new_domain] << new_url.substr(2, new_url.len - 1)

		}else {
			if links.links[n_domain].contains(new_url) { continue }
			links.links[n_domain] << new_url
		}

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

fn loop(configure Config, mut links Links, ac_domain string, index int, counter_to_save int) {
	if configure.time_sleep > 0 { time.sleep(configure.time_sleep.nanoseconds() * time.second) }

	if index >= links.links[ac_domain].len || configure.exclude_domains.contains(ac_domain) {

		if !configure.exit_domain { return }

		if configure.save_every_level_change {
			print("Saving...\n")
			save_to_file(configure, links)
		}

		new_domain := get_next_domain(mut links, ac_domain)

		if new_domain == '' { return }
		loop(
			configure,
			mut links,
			new_domain,
			0,
			counter_to_save
		)
		return
	}
	url := ac_domain+links.links[ac_domain][index]

	if configure.debug { print("$url\n") }

	get_links(mut links, url, ac_domain, configure)

	mut new_count_to_save := counter_to_save +1
	if configure.amount_of_lines_before_save > 1 && configure.amount_of_lines_before_save == counter_to_save {
		print("Saving...\n")
		new_count_to_save = 0
		save_to_file(configure, links)
	}

	loop(configure, mut links, ac_domain, index + 1, new_count_to_save)
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

	loop(con, mut v_links, domain, 0, 0)

	save_to_file(con, v_links)
}