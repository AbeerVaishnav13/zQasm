const std = @import("std");
const mem = std.mem;
const Token = @import("tokenize.zig").Token;
const Tokenizer = @import("tokenize.zig").Tokenizer;

pub const Parser = struct {
    buffer: []const u8,
    tokenizer: *Tokenizer,
    state: State,

    pub fn init(tokenizer: *Tokenizer) Parser {
        return Parser{ .tokenizer = tokenizer, .state = .start };
    }

    const State = enum {
        start,
        program,
        globalStatement,
        statement,
        header,
        version,
        include,
        io,
        ioIdentifier,
        classicalType,
        subroutineDefinition,
        externDeclaration,
        quantumGateDefinition,
        quantumDeclarationStatement,
        calibration,
        pragma,
        expressionStatement,
        assignmentStatement,
        classicalDeclarationStatement,
        branchingStatement,
        loopStatement,
        endStatement,
        aliasStatement,
        quantumStatement,
        end,
    };

    const Keywords = enum {
        Identifier,

        // Includes
        Include,
        OpenQASM,

        // Global statements
        Def,
        Extern,
        Gate,
        Defcal,
        Defcalgrammar,
        Pragma,

        // Quantum types
        Qubit,
        Qreg,

        // Quantum Gate names
        U,
        CX,
        Reset,
        Measure,
        Barrier,
        Inv,
        Ctrl,
        Negctrl,
        Pow,
        At,

        // Classical types
        Bit,
        Creg,
        Int,
        Uint,
        Float,
        Angle,
        Complex,
        Bool,
        Fixed,

        // Timing types
        Duration,
        Stretch,
        Box,
        Durationof,

        // Time instructions
        Delay,
        Rotary,

        // Time units
        Dt,
        Ns,
        Us,
        Ms,
        S,

        // Boolean literals
        True,
        False,

        // Constant type
        Const,

        // Math
        Pi,
        Sin,
        Cos,
        Tan,
        Exp,
        Ln,
        Sqrt,
        Rotl,
        Rotr,
        Popcount,

        // I/O modifiers
        Input,
        Output,

        // Flow control
        For,
        While,
        If,
        Else,
        End,
        Return,
        Break,
        Continue,

        fn string_to_enum(token: []const u8) Keywords {
            if (mem.eql(u8, token, "include")) {
                return .Include;
            } else if (mem.eql(u8, token, "OPENQASM")) {
                return .OpenQASM;
            } else if (mem.eql(u8, token, "def")) {
                return .Def;
            } else if (mem.eql(u8, token, "extern")) {
                return .Extern;
            } else if (mem.eql(u8, token, "gate")) {
                return .Gate;
            } else if (mem.eql(u8, token, "defcal")) {
                return .Defcal;
            } else if (mem.eql(u8, token, "defcalgrammar")) {
                return .Defcalgrammar;
            } else if (mem.eql(u8, token, "#pragma")) {
                return .Pragma;
            } else if (mem.eql(u8, token, "qubit")) {
                return .Qubit;
            } else if (mem.eql(u8, token, "qreg")) {
                return .Qreg;
            } else if (mem.eql(u8, token, "U")) {
                return .U;
            } else if (mem.eql(u8, token, "CX")) {
                return .CX;
            } else if (mem.eql(u8, token, "reset")) {
                return .Reset;
            } else if (mem.eql(u8, token, "measure")) {
                return .Measure;
            } else if (mem.eql(u8, token, "barrier")) {
                return .Barrier;
            } else if (mem.eql(u8, token, "inv")) {
                return .Inv;
            } else if (mem.eql(u8, token, "ctrl")) {
                return .Ctrl;
            } else if (mem.eql(u8, token, "negctrl")) {
                return .Negctrl;
            } else if (mem.eql(u8, token, "pow")) {
                return .Pow;
            } else if (mem.eql(u8, token, "@")) {
                return .At;
            } else if (mem.eql(u8, token, "bit")) {
                return .Bit;
            } else if (mem.eql(u8, token, "creg")) {
                return .Creg;
            } else if (mem.eql(u8, token, "int")) {
                return .Int;
            } else if (mem.eql(u8, token, "uint")) {
                return .Uint;
            } else if (mem.eql(u8, token, "float")) {
                return .Float;
            } else if (mem.eql(u8, token, "angle")) {
                return .Angle;
            } else if (mem.eql(u8, token, "fixed")) {
                return .Fixed;
            } else if (mem.eql(u8, token, "complex")) {
                return .Complex;
            } else if (mem.eql(u8, token, "bool")) {
                return .Bool;
            } else if (mem.eql(u8, token, "duration")) {
                return .Duration;
            } else if (mem.eql(u8, token, "stretch")) {
                return .Stretch;
            } else if (mem.eql(u8, token, "box")) {
                return .Box;
            } else if (mem.eql(u8, token, "durationof")) {
                return .Durationof;
            } else if (mem.eql(u8, token, "delay")) {
                return .Delay;
            } else if (mem.eql(u8, token, "rotary")) {
                return .Rotary;
            } else if (mem.eql(u8, token, "dt")) {
                return .Dt;
            } else if (mem.eql(u8, token, "ns")) {
                return .Ns;
            } else if (mem.eql(u8, token, "us") or mem.eql(u8, token, "µs")) {
                return .Us;
            } else if (mem.eql(u8, token, "ms")) {
                return .Ms;
            } else if (mem.eql(u8, token, "s")) {
                return .S;
            } else if (mem.eql(u8, token, "true")) {
                return .True;
            } else if (mem.eql(u8, token, "false")) {
                return .False;
            } else if (mem.eql(u8, token, "const")) {
                return .Const;
            } else if (mem.eql(u8, token, "pi")) {
                return .Pi;
            } else if (mem.eql(u8, token, "sin")) {
                return .Sin;
            } else if (mem.eql(u8, token, "cos")) {
                return .Cos;
            } else if (mem.eql(u8, token, "tan")) {
                return .Tan;
            } else if (mem.eql(u8, token, "exp")) {
                return .Exp;
            } else if (mem.eql(u8, token, "ln")) {
                return .Ln;
            } else if (mem.eql(u8, token, "sqrt")) {
                return .Sqrt;
            } else if (mem.eql(u8, token, "rotl")) {
                return .Rotl;
            } else if (mem.eql(u8, token, "rotr")) {
                return .Rotr;
            } else if (mem.eql(u8, token, "popcount")) {
                return .Popcount;
            } else if (mem.eql(u8, token, "input")) {
                return .Input;
            } else if (mem.eql(u8, token, "output")) {
                return .Output;
            } else if (mem.eql(u8, token, "for")) {
                return .For;
            } else if (mem.eql(u8, token, "while")) {
                return .While;
            } else if (mem.eql(u8, token, "if")) {
                return .If;
            } else if (mem.eql(u8, token, "else")) {
                return .Else;
            }

            return .Invalid;
        }
    };

    fn get_next_state(self: *Parser) State {
        const next_token = self.tokenizer.top();
        const keyword = Keywords.string_to_enum(next_token.data);
        return switch (self.state) {
            .program => switch (keyword) {
                .Def, .Extern, .Gate, .Qubit, .Qreg, .Defcal, .Defcalgrammar, .Pragma => .globalStatement,
                else => .statement,
            },
            .globalStatement => switch (keyword) {
                .Def => .subroutineDefinition,
                .Extern => .externDeclaration,
                .Gate => .quantumGateDefinition,
                .Qubit => .quantumDeclarationStatement,
                .Defcal, .Defcalgrammar => .calibration,
                .Pragma => .pragma,
            },

            .statement => {},

            .subroutineDefinition => {},

            .externDeclaration => {},

            .quantumGateDefinition => {},

            .quantumDeclarationStatement => {},

            .calibration => {},

            .pragma => {},
        };
    }

    // const parserError = error{
    //     versionError,
    // };

    pub fn parse(self: *Parser) !void {
        // program
        self.program();
    }

    fn program(self: *Parser) !void {
        self.state = .program;

        // Ignore initial comments
        var token = self.tokenizer.top();
        while (token.id == .line_comment or token.id == .multi_line_comment)
            token = self.tokenizer.next();
        self.tokenizer.restore_ptr();

        // header
        self.header();

        // program1: (globalStatement | statement)*
        self.program1();

        self.state = .end;
    }

    fn program1(self: *Parser) !void {
        // globalStatement
        if (self.get_next_state() == .globalStatement) {
            self.globalStatement();
        }

        // statement
        else if (self.get_next_state() == .statement) {
            self.statement();
        }

        // If no globalStatement/statement
        else return;

        self.program1();
    }

    fn header(self: *Parser) !void {
        const prev_state = self.state;
        self.state = .header;

        // version
        self.version();

        // include
        token = self.tokenizer.top();
        if (Keywords.string_to_enum(token.data) == .Include)
            self.include();

        // io
        token = self.tokenizeer.top();
        if (Keywords.string_to_enum(token.data) == .Input or Keywords.string_to_enum(token.data) == .Output)
            self.io();

        self.state = prev_state;
    }

    fn version(self: *Parser) !void {
        const prev_state = self.state;
        self.state = .version;

        // OPENQASM
        var token = self.tokenizer.next();
        if (Keywords.string_to_enum(token.data) != .OpenQASM) {
            std.debug.print("VersionError ({}:{}) : Expected 'OPENQASM <version>' statement.", .{ token.line_num, token.col_num });
            std.process.exit(-1);
        }

        // Version number
        token = self.tokenizer.next();
        if (!(token.id == .integer_literal or token.id == .float_literal)) {
            std.debug.print("VersionError ({}:{}) : Expected integer or float value for <version>, found {}.", .{ token.line_num, token.col_numo, token.data });
            std.process.exit(-1);
        }

        // Semicolon
        token = self.tokenizer.next();
        if (token.id != .semicolon) {
            std.debug.print("StatementError ({}:{}): Expected ';' found '{}'.", .{ token.line_num, token.col_num, token.data });
            std.process.exit(-1);
        }

        self.state = prev_state;
    }

    fn include(self: *Parser) !void {
        const prev_state = self.state;
        self.state = .include;

        // include
        // Consume 'include' token as it's checked already
        var token = self.tokenizer.next();

        // string_literal
        token = self.tokenizer.next();
        if (token.id != .string_literal) {
            std.debug.print("IncludeError ({}:{}) : Expected include_filename string, found '{}'.", .{ token.line_num, token.col_num, token.data });
            std.process.exit(-1);
        }

        // Semicolon
        token = self.tokenizer.next();
        if (token.id != .semicolon) {
            std.debug.print("StatementError ({}:{}): Expected ';' found '{}'.", .{ token.line_num, token.col_num, token.data });
            std.process.exit(-1);
        }

        token = self.tokenizer.top();
        if (Keywords.string_to_enum(token.data) == .Include)
            self.include();

        self.state = prev_state;
    }

    fn io(self: *Parser) !void {
        const prev_state = self.state;
        self.state = .io;

        // ioIdentifier
        // Consume next token for ioIdentifier as it's already checked
        var token = self.tokenizer.next();

        // classicalType
        token = self.tokenizer.next();
        switch (Keywords.string_to_enum(token.data)) {
            .Bit, .Creg, .Int, .Uint, .Float, .Angle, .Complex, .Bool, .Fixed => {},
            else => {
                std.debug.print("StatementError ({}:{}) : Expected classical type, found '{}'", .{ token.line_num, token.col_num, token.data });
                std.process.exit(-1);
            },
        }

        // Identifier
        token = self.tokenizer.next();
        if (Keywords.string_to_enum(token.data) != .Identifier) {
            std.debug.print("StatementError ({}:{}) : Expected identifier, found '{}'", .{ token.line_num, token.col_num, token.data });
            std.process.exit(-1);
        }

        // Semicolon
        token = self.tokenizer.next();
        if (token.id != .semicolon) {
            std.debug.print("StatementError ({}:{}): Expected ';' found '{}'.", .{ token.line_num, token.col_num, token.data });
            std.process.exit(-1);
        }

        self.state = prev_state;
    }
};
