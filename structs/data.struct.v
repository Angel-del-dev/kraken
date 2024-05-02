module structs

import time

// Links
pub struct Links {
pub mut:
	links map[string][]string
}

pub fn (mut l Links) add(link string, domain string) {
	l.links[domain] << link
}


// Config

pub struct Config {
pub:
	url string
	exclude_domains []string
	output string
	time_sleep time.Duration
	exit_domain bool
	debug bool
}