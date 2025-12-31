#pragma once

#include <istream>
#include <string>
#include <vector>


namespace nested {

enum token_type {
	TEXT,
	KEY,
	OPEN_NESTED,
	CLOSE_NESTED,
	ERROR,
	END,
};

constexpr const char *token_type_name(token_type t) {
	switch (t) {
		case TEXT: return "TEXT";
		case KEY: return "KEY";
		case OPEN_NESTED: return "OPEN_NESTED";
		case CLOSE_NESTED: return "CLOSE_NESTED";
		case ERROR: return "ERROR";
		case END: return "END";
		default:
			return "";
	}
}

template<class CharT, class Traits = std::char_traits<CharT>, class Allocator = std::allocator<CharT>>
class basic_scanner {
public:
	using char_type = CharT;
	using traits_type = Traits;
	using int_type = typename traits_type::int_type;
	using istream = std::basic_istream<char_type, traits_type>;

	struct token {
		std::basic_string<CharT, Traits, Allocator> text;
		int line;
		int column;
		token_type type;
		char_type quote;
	};

	class iterator {
	public:
		using value_type = token;

		iterator(basic_scanner* scanner) : scanner(scanner) {}

		const value_type& operator*() const {
			return scanner->current_token;
		}
		const value_type* operator->() const {
			return &scanner->current_token;
		}

		iterator& operator++() {
			scanner->move_next();
			return *this;
		}
		iterator operator++(int) {
			auto previous = *this;
			operator++();
			return previous;
		}

		bool operator==(const iterator& other) const {
			return scanner == other.scanner
				|| (other.scanner == nullptr && scanner->current_token.type == END);
		}
		bool operator!=(const iterator& other) const {
			return !operator==(other);
		}

	private:
		basic_scanner* scanner;
	};

	basic_scanner(istream& stream) : stream(stream) {
		move_next();
	}

	iterator begin() {
		return iterator(this);
	}
	iterator end() {
		return iterator(nullptr);
	}

	bool move_next() {
		while (true) {
			skip_whitespace();

			int_type c = stream.get();
			++column;
			switch (c) {
				case traits_type::eof():
					if (!expected_closing_stack.empty()) {
						current_token.type = ERROR;
						current_token.text = "Expected closing block with '";
						current_token.text += expected_closing_stack.back();
						current_token.text += "'";
						current_token.line = line;
						current_token.column = column;
						current_token.quote = 0;
						expected_closing_stack.pop_back();
						--column;
					}
					else {
						current_token.type = END;
					}
					return false;

				case '[':
					return process_open_nested(traits_type::to_char_type(c), ']');

				case '{':
					return process_open_nested(traits_type::to_char_type(c), '}');

				case '(':
					return process_open_nested(traits_type::to_char_type(c), ')');

				case ']':
				case '}':
				case ')':
					return process_close_nested(traits_type::to_char_type(c));

				case ':':
					// Note: correct KEY token is handled inside `process_quoted_text` / `process_unquoted_text`
					current_token.type = ERROR;
					current_token.text = "Unexpected key-value ':'";
					current_token.line = line;
					current_token.column = column;
					current_token.quote = 0;
					return false;

				case '\'':
				case '"':
				case '`':
					return process_quoted_text(traits_type::to_char_type(c));

				default:
					return process_unquoted_text(traits_type::to_char_type(c));
			}
		}
	}

	const token& get_current_token() {
		return current_token;
	}

private:
	istream& stream;
	std::vector<CharT, Allocator> expected_closing_stack;
	token current_token;

	int line = 1;
	int column = 0;

	void skip_whitespace() {
		while (true) {
			switch (stream.peek()) {
				case ' ':
				case ',':
				case ';':
				case '\t':
				case '\r':
					stream.get();
					++column;
					break;

				case '\n':
					stream.get();
					++line;
					column = 0;
					break;

				case '#':
					while (stream.good() && stream.peek() != '\n') {
						stream.get();
						++column;
					}
					break;

				default:
					return;
			}
		}
	}

	bool process_open_nested(char_type c, char_type expected_closing_char) {
		expected_closing_stack.push_back(expected_closing_char);
		current_token.text = c;
		current_token.type = OPEN_NESTED;
		current_token.quote = 0;
		current_token.line = line;
		current_token.column = column;
		return true;
	}

	bool process_close_nested(char_type c) {
		current_token.line = line;
		current_token.column = column;
		current_token.quote = 0;
		if (expected_closing_stack.empty()) {
			current_token.type = ERROR;
			current_token.text = "Unexpected closing block '";
			current_token.text += c;
			current_token.text += "'";
			return false;
		}
		else if (expected_closing_stack.back() != c) {
			current_token.type = ERROR;
			current_token.text = "Expected closing block with '";
			current_token.text += expected_closing_stack.back();
			current_token.text += "', but found '";
			current_token.text += c;
			current_token.text += "'";
			expected_closing_stack.pop_back();
			return false;
		}
		else {
			current_token.text = c;
			current_token.type = CLOSE_NESTED;
			expected_closing_stack.pop_back();
			return true;
		}
	}

	bool process_unquoted_text(char_type first_char) {
		current_token.type = TEXT;
		current_token.line = line;
		current_token.column = column;
		current_token.quote = 0;

		current_token.text = first_char;
		while (true) {
			switch (stream.peek()) {
				case ' ':
				case ',':
				case ';':
				case '\t':
				case '\r':
				case '\n':
					skip_whitespace();
					if (stream.peek() != ':') {
						return true;
					}
					// fallthrough
				case ':':
					current_token.type = KEY;
					stream.get();
					++column;
					return true;

				case '[':
				case ']':
				case '{':
				case '}':
				case '(':
				case ')':
				case traits_type::eof():
					return true;

				default:
					current_token.text.push_back(stream.get());
					++column;
					break;
			}
		}
	}

	bool process_quoted_text(char_type quote) {
		current_token.type = TEXT;
		current_token.line = line;
		current_token.column = column;
		current_token.quote = quote;

		current_token.text.clear();
		while (true) {
			int_type c = stream.peek();
			if (c == traits_type::eof()) {
				current_token.type = ERROR;
				current_token.text = "Unmatched closing quote ";
				current_token.text += quote;
				return false;
			}
			else if (c == quote) {
				// consume quote
				stream.get();
				++column;
				// if 2 quotation marks are found in sequence, add one to text and keep reading
				if (stream.peek() == quote) {
					current_token.text.push_back(stream.get());
					++column;
				}
				// otherwise, text is finished
				else {
					skip_whitespace();
					if (stream.peek() == ':') {
						current_token.type = KEY;
						stream.get();
						++column;
					}
					return true;
				}
			}
			else {
				current_token.text.push_back(stream.get());
				if (c == '\n') {
					++line;
					column = 0;
				}
				else {
					++column;
				}
			}
		}
	}
};

using scanner = basic_scanner<char>;

}

/* Example program that reads argv[1] and print all tokens read */
/*
#include <iostream>
#include <sstream>

int main(int argc, const char **argv) {
	if (argc < 2) {
		std::cout << "USAGE: " << argv[0] << " TEXT_CONTENT" << std::endl;
		return 1;
	}
	std::stringstream stream(argv[1]);
	nested::scanner scanner(stream);
	for (auto&& it : scanner) {
		std::cout << token_type_name(it.type) << " '" << it.text << "' @ " << it.line << " " << it.column << std::endl;
	}
}
*/
