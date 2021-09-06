const std = @import("std");
const mem = std.mem;

pub const Token = struct {
    data: []const u8,
    id: Id,
    line_num: usize,
    col_num: usize,
    start: usize,
    end: usize,

    pub const Id = enum {
        invalid, // Just for info
        identifier, // Any words
        string_literal, // Strings
        integer_literal, // Integers
        float_literal, // Floats
        boolean_literal, // Booleans
        timing_unit_literal, // Timings
        semicolon, // ;
        colon, // :
        comma, // ,
        line_comment, // //
        multi_line_comment, // /*...*/
        line_break, // \n, \r
        equal_to, // =
        less_than, // <
        greater_than, // >
        plus, // +
        minus, // -
        mul, // *
        div, // /
        logical_and, // &&
        logical_or, // ||
        logical_not, // !
        bitwise_and, // &
        bitwise_or, // |
        bitwise_xor, // ^
        bitwise_not, // ~
        bracket_square_open, // [
        bracket_square_close, // ]
        bracket_round_open, // (
        bracket_round_close, // )
        bracket_curly_open, // {
        bracket_curly_close, // }
        dot, // .
        at, // @
        hash_pragma, // #pragma
        arrow, // ->
        eof, // As a ending condition
    };
};

pub const Tokenizer = struct {
    buffer: []const u8,
    index: usize,
    line_num: usize,
    prev_line_break_index: usize,
    prev_token_start: usize,

    pub fn init(buffer: []const u8) Tokenizer {
        return Tokenizer{
            .buffer = buffer,
            .index = 0,
            .line_num = 0,
            .prev_line_break_index = 0,
            .prev_token_start = 0,
        };
    }

    const State = enum {
        start,
        identifier,
        string_literal,
        integer_literal,
        float_fraction_number,
        float_exponent_number,
        boolean_literal,
        timing_unit_literal,
        bool_or_timing,
        line_comment,
        multi_line_comment,
        multi_line_comment_end,
        line_break,
        slash,
        hyphen,
        ampersand,
        pipe,
    };

    pub fn restore_ptr(self: *Tokenizer) void {
        if (self.prev_token_start != 0) {
            self.index = self.prev_token_start;
        }
        self.prev_token_start = 0;
    }

    pub fn next(self: *Tokenizer) Token {
        self.prev_token_start = self.index;
        const start_index = self.index;
        var prev_line_start: usize = 0; // TODO: Fix this hack for calculating line break col_num
        var state: State = .start;
        var result = Token{
            .data = undefined,
            .id = .eof,
            .line_num = 0,
            .col_num = 0,
            .start = self.index,
            .end = undefined,
        };

        while (self.index < self.buffer.len) : (self.index += 1) {
            const c = self.buffer[self.index];
            switch (state) {
                .start => switch (c) {
                    ' ', '\t', '\r' => {
                        result.start = self.index + 1;
                    },
                    '\n' => {
                        result.id = .line_break;
                        self.line_num += 1;
                        prev_line_start = self.prev_line_break_index;
                        self.prev_line_break_index = self.index;
                        state = .line_break;
                    },
                    '"' => {
                        result.id = .string_literal;
                        state = .string_literal;
                    },
                    'a'...'z', 'A'...'Z', '_' => {
                        result.id = .identifier;
                        state = .identifier;
                    },
                    ',' => {
                        result.id = .comma;
                        self.index += 1;
                        break;
                    },
                    ':' => {
                        result.id = .colon;
                        self.index += 1;
                        break;
                    },
                    ';' => {
                        result.id = .semicolon;
                        self.index += 1;
                        break;
                    },
                    '.' => {
                        result.id = .dot;
                        self.index += 1;
                        break;
                    },
                    '=' => {
                        result.id = .equal_to;
                        self.index += 1;
                        break;
                    },
                    '+' => {
                        result.id = .plus;
                        self.index += 1;
                        break;
                    },
                    '-' => {
                        state = .hyphen;
                    },
                    '*' => {
                        result.id = .mul;
                        self.index += 1;
                        break;
                    },
                    '/' => {
                        state = .slash;
                    },
                    '<' => {
                        result.id = .less_than;
                        self.index += 1;
                        break;
                    },
                    '>' => {
                        result.id = .greater_than;
                        self.index += 1;
                        break;
                    },
                    '&' => {
                        state = .ampersand;
                    },
                    '|' => {
                        state = .pipe;
                    },
                    '[' => {
                        result.id = .bracket_square_open;
                        self.index += 1;
                        break;
                    },
                    ']' => {
                        result.id = .bracket_square_close;
                        self.index += 1;
                        break;
                    },
                    '(' => {
                        result.id = .bracket_round_open;
                        self.index += 1;
                        break;
                    },
                    ')' => {
                        result.id = .bracket_round_close;
                        self.index += 1;
                        break;
                    },
                    '{' => {
                        result.id = .bracket_curly_open;
                        self.index += 1;
                        break;
                    },
                    '}' => {
                        result.id = .bracket_curly_close;
                        self.index += 1;
                        break;
                    },
                    '^' => {
                        result.id = .bitwise_xor;
                        self.index += 1;
                        break;
                    },
                    '~' => {
                        result.id = .bitwise_not;
                        self.index += 1;
                        break;
                    },
                    '!' => {
                        result.id = .logical_not;
                        self.index += 1;
                        break;
                    },
                    '@' => {
                        result.id = .at;
                        self.index += 1;
                        break;
                    },
                    '#' => {
                        const token = self.buffer[self.index..(self.index + 7)];
                        if (mem.eql(u8, token, "#pragma")) {
                            result.id = .hash_pragma;
                            self.index += 7;
                            break;
                        }
                    },
                    '0'...'9' => {
                        result.id = .integer_literal;
                        state = .integer_literal;
                    },
                    else => {
                        result.id = .invalid;
                        self.index += 1;
                        break;
                    },
                },

                .line_break => switch (c) {
                    '\n', '\r' => {
                        self.line_num += 1;
                        prev_line_start = self.prev_line_break_index;
                        self.prev_line_break_index = self.index;
                    },
                    else => break,
                },

                .identifier => switch (c) {
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => {},
                    else => {
                        state = .bool_or_timing;
                        self.index -= 1;
                    },
                },

                .bool_or_timing => {
                    const identifier_start_character = self.buffer[start_index];
                    state = switch (identifier_start_character) {
                        't', 'f' => .boolean_literal,
                        'd', 'n', 'u', 'µ', 'm', 's' => .timing_unit_literal,
                        else => break,
                    };
                    self.index -= 1;
                },

                .boolean_literal => {
                    const token = self.buffer[start_index .. self.index - 1];
                    if (mem.eql(u8, token, "true") or mem.eql(u8, token, "false")) {
                        result.id = .boolean_literal;
                    }
                    break;
                },

                .timing_unit_literal => {
                    const token = self.buffer[start_index..self.index];
                    if (mem.eql(u8, token, "dt") or
                        mem.eql(u8, token, "ns") or
                        mem.eql(u8, token, "us") or
                        mem.eql(u8, token, "µs") or
                        mem.eql(u8, token, "ms") or
                        mem.eql(u8, token, "s"))
                    {
                        result.id = .timing_unit_literal;
                    }
                    break;
                },

                .string_literal => switch (c) {
                    '"' => {
                        self.index += 1;
                    },
                    else => break,
                },

                .integer_literal => switch (c) {
                    '.' => {
                        result.id = .float_literal;
                        state = .float_fraction_number;
                    },
                    'e', 'E' => {
                        result.id = .float_literal;
                        state = .float_exponent_number;
                    },
                    '0'...'9' => {},
                    else => break,
                },

                .float_fraction_number => switch (c) {
                    'e', 'E' => {
                        state = .float_exponent_number;
                    },
                    '0'...'9' => {},
                    else => break,
                },

                .float_exponent_number => switch (c) {
                    '+', '-' => {},
                    '0'...'9' => {},
                    else => break,
                },

                .slash => switch (c) {
                    '/' => {
                        state = .line_comment;
                        result.id = .line_comment;
                    },
                    '*' => {
                        state = .multi_line_comment;
                        result.id = .multi_line_comment;
                    },
                    else => {
                        result.id = .div;
                        break;
                    },
                },

                .hyphen => switch (c) {
                    '>' => {
                        result.id = .arrow;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.id = .minus;
                        break;
                    },
                },

                .ampersand => switch (c) {
                    '&' => {
                        result.id = .logical_and;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.id = .bitwise_and;
                        break;
                    },
                },

                .pipe => switch (c) {
                    '|' => {
                        result.id = .logical_or;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.id = .bitwise_or;
                        break;
                    },
                },

                .line_comment => switch (c) {
                    '\n' => break,
                    else => continue,
                },

                .multi_line_comment => switch (c) {
                    '*' => {
                        state = .multi_line_comment_end;
                    },
                    '\n' => {
                        self.line_num += 1;
                        prev_line_start = self.prev_line_break_index;
                    },
                    else => continue,
                },

                .multi_line_comment_end => switch (c) {
                    '/' => {
                        self.index += 1;
                        if (self.buffer[self.index] == '\n') break;
                    },
                    '\n' => {
                        self.line_num += 1;
                        prev_line_start = self.prev_line_break_index;
                    },
                    else => state = .multi_line_comment,
                },
            }
        }

        result.end = self.index;
        result.line_num = switch (result.id) {
            .line_break => self.line_num,
            else => self.line_num + 1,
        };
        result.col_num = switch (result.id) {
            .line_break => self.prev_line_break_index - prev_line_start,
            .multi_line_comment => result.start - self.prev_line_break_index, // TODO: Fix col_num if first line is multi-line comment
            else => result.start - self.prev_line_break_index,
        };
        result.data = self.buffer[result.start..result.end];
        return result;
    }

    pub fn top(self: *Tokenizer) Token {
        const line = self.line_num;
        const token = self.next();
        self.restore_ptr();
        self.line_num = line;
        return token;
    }
};
