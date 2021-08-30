const std = @import("std");
const Tokenizer = @import("tokenize.zig").Tokenizer;
const Token = @import("tokenize.zig").Token;

//const input_file = @embedFile("../qasm_code_samples/teleport.qasm");
const input_file = @embedFile("../qasm_code_samples/vqe.qasm");

pub fn main() anyerror!void {
    var tokenizer = Tokenizer.init(input_file);
    while (true) {
        const token = tokenizer.next();
        std.debug.print("{s} \t\t\t| {}\n", .{ input_file[token.start..token.end], token });
        if (token.id == .eof) break;
    }
}
