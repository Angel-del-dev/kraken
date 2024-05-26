module main

import structs { Links, Config, Parser }
import net.http
import net.html
import os
import json
import time

fn output_ks(file_name string, text string) {
	mut new_text := ''
	if os.is_file(file_name) {
		new_text = os.read_file(file_name) or {
			print('KrakenScript error: Could not read contents from <<$file_name>>\n')
			exit(41)
		}
		new_text = '$new_text,$text'
	}
	os.write_file('$file_name', new_text) or {
		print('KrakenScript error: Could not write to file <<$file_name>>\n')
		exit(91)
	}
}

fn get_data_restricted_ks(elements []&html.Tag, d_type string, delimiter string) string {
	mut data := []string{}

	for element in elements {
		mut content := ''
		match d_type {
			'content' {
				content = element.content
				if content == '' { continue }

			}
			'attrcontent' {
				content = element.attributes['content']
				if content.replace(' ', '') == '' { continue }
			}
			else {
				print('KrakenScript error: Action attribute <<$d_type>> not allowed')
				exit(8)
			}
		}
		data << content
	}
	return data.join(delimiter)
}

fn exec_actions_ks(actions []structs.Action, dom html.DocumentObjectModel) string {
	mut text := ''
	for action in actions {
		match action.action_type.to_lower() {
			'element' {
				elements := dom.get_tags(name: action.value.to_lower())
				text = text+action.delimiter+get_data_restricted_ks(elements, action.attribute.to_lower(), action.delimiter)
			}
			else {
				print('KrakenScript error: Unknown action type <<'+action.action_type+'>>\n')
				exit(10)
			}
		}
	}
	return text
}

fn exec_script_ks(p Parser, dom html.DocumentObjectModel) {
	for block in p.blocks {
		b_type := block.block_type
		param := block.action_param
		match b_type.to_lower() {
			'output' {
				text := exec_actions_ks(block.actions, dom)
				output_ks(param, text)
			}
			else {
				print("KrakenScript error: Unknown block type [$b_type]\n")
				exit(90)
			}
		}
	}
}

fn get_links(mut links Links, url string, domain string, configuration Config, p Parser) {
	contents := http.get(url) or {
		print("Saving because of error encounted\n")
		save_to_file(configuration, links)
		print('Error parsing <<$url>>\n')
		exit(81)
	}

	dom := html.parse(contents.str())

	a_tags := dom.get_tags(name: 'a')

	if p.blocks.len > 0 { exec_script_ks(p, dom) }

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

fn loop(configure Config, mut links Links, ac_domain string, index int, counter_to_save int, p Parser) {
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
			counter_to_save,
			p
		)
		return
	}
	url := ac_domain+links.links[ac_domain][index]

	if configure.debug { print("$url\n") }

	get_links(mut links, url, ac_domain, configure, p)

	mut new_count_to_save := counter_to_save +1
	if configure.amount_of_lines_before_save > 1 && configure.amount_of_lines_before_save == counter_to_save {
		print("Saving...\n")
		new_count_to_save = 0
		save_to_file(configure, links)
	}

	loop(configure, mut links, ac_domain, index + 1, new_count_to_save, p)
}

fn read_config(file string) Config {
	conf_str := os.read_file(file) or {
		print('File <<$file>> could not be found\n')
		exit(71)
	}
	c := json.decode(Config, conf_str) or {
		print('Invalid configuration')
		exit(71)
	}
	return c
}

fn save_to_file(configuration Config, lin Links) {
	f_json := json.encode(lin)
	file := configuration.output
	os.write_file(file, f_json) or {
		print('Could not create file <<$file>>\n')
		exit(61)
	}
}

fn main() {
	conf_file := os.args[1]
	con := read_config(conf_file)
	mut p := Parser{}
	if con.run != '' { p.parse(con.run) }

	mut v_links := Links{}

	mut domain, link := format_url('', con.url)

	v_links.add(link, domain)

	loop(
		con, mut v_links, domain,
		0, 0,
		p
	)

	save_to_file(con, v_links)
}