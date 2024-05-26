module structs

import os


pub struct Action {
pub mut:
	action_type string
	value string
	attribute string
	delimiter string
}

struct Block {
pub mut:
	block_type string
	action_param string
	actions []Action
}

pub struct Parser {
pub mut:
	blocks []Block
}

pub fn (mut p Parser) new_block(b_type string, param string) {
	p.blocks << Block{
		block_type: b_type
		action_param: param
	}
}

pub fn (mut p Parser) add_action(a_type string, value string, attribute string, delimiter string) {
	p.blocks[p.blocks.len - 1].actions << Action{
		action_type: a_type
		value: value
		attribute: attribute
		delimiter: delimiter
	}
}

// Parser actions

fn get_text_to_delimiter(i int, text string, delimiter string)(int, string) {
	mut j := i
	mut word := ''
	for {
		j++
		ch := text[j].ascii_str()
		if ch == delimiter { break }
		word = "$word$ch"
	}
	return j, word
}

fn (mut p Parser) parse_actions(i int, text string) int {
	t_len := text.len
	mut j := i
	mut word := ''
	for {
		if j >= t_len { break }
		ch := text[j].ascii_str()
		match ch {
			'(' {
				j--
				break
			}
			'[' {
				j, word = get_text_to_delimiter(j, text, ']')
				action := word
				j, word = get_text_to_delimiter(j, text, '~')
				value := word.replace(' ', '')
				j, word = get_text_to_delimiter(j, text, '|')
				attribute := word.replace(' ', '')
				j, word = get_text_to_delimiter(j, text, '|')
				delimiter := word.replace(' ', '')
				p.add_action(action, value, attribute, delimiter)
			}
			else {
				print('KrakenScript error: Invalid character <<$ch>>')
				exit(1)
			}
		}
		j++
	}
	return j
}

pub fn (mut p Parser) parse(file string) {
	script := os.read_file(file) or {
		panic('File <<$file>> could not be found')
	}
	mut i := 0
	mut len := script.len
	mut word := ''
	mut value := ''
	for {
		if i >= len  { break }
		ch := script[i].ascii_str()
		match ch {
			' ' {
				word = ''
				value = ''
				i++
				continue
			}
		 	'(' {
				i, word = get_text_to_delimiter(i, script, ')')
				i, value = get_text_to_delimiter(i, script, ':')
				i++ // Remove ':'
			 	p.new_block(word, value.replace(' ', ''))
				i = p.parse_actions(i, script)
				value = ''
				word = ''
		 	}
			else {
				print('KrakenScript error: Invalid character <<$ch>>')
				exit(1)
			}
		}
		i++
	}
}
