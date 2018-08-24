def initialize_environment
  # Use argument as assembly file to process
  asm_file = ARGV[0]

  # Extract path for output file
  path = /^.*\./.match(asm_file)

  # Setup globals
  @asm = IO.readlines(asm_file).map { |str| str.split("//")[0].strip }
  @hack = File.open("#{path}hack", "w")
  @address = nil
  @symbol_table = Hash.new()

  # Strip comment lines and blank lines from instructions
  @asm.select! { |line| /\S/ =~ line && /^(\/\/).*/ !~ line}

end

def populate_predefined_symbols
  register_aliases = Hash.new()
  0.upto(15).each do |n|
    register_aliases[:"R#{n}"] = ("%016b" % n)
  end
  predefined_symbols = { SP: "0000000000000000", LCL: "0000000000000001", ARG: "0000000000000010", THIS: "0000000000000011", THAT: "0000000000000100", SCREEN: "0100000000000000", KBD: "0110000000000000" }
  @symbol_table.merge!(predefined_symbols).merge!(register_aliases)
end

# Sets last three bits for jump condition
def gen_jump_cond(cond)
  case cond
  when "JGT"
    "001"
  when "JEQ"
    "010"
  when "JGE"
    "011"
  when "JLT"
    "100"
  when "JNE"
    "101"
  when "JLE"
    "110"
  when "JMP"
    "111"
  end
end

# Set dest bits for jump
def gen_dest(dest)
  a = /A/ =~ dest ? "1" : "0"
  d = /D/ =~ dest ? "1" : "0"
  m = /M/ =~ dest ? "1" : "0"
  return "#{a}#{d}#{m}"
end

# Set comp bits
def gen_comp(comp)
  comp = comp.gsub("M", "A")
  case comp
  when "0"
    "101010"
  when "1"
    "111111"
  when "-1"
    "111010"
  when "D"
    "001100"
  when "A"
    "110000"
  when "!D"
    "001101"
  when "!A"
    "110001"
  when "-D"
    "001101"
  when "-A"
    "110011"
  when "D+1"
    "011111"
  when "A+1"
    "110111"
  when "D-1"
    "001110"
  when "A-1"
    "110010"
  when "D+A"
    "000010"
  when "D-A"
    "010011"
  when "A-D"
    "000111"
  when "D&A"
    "000000"
  when "D|A"
    "010101"
  end
end

# Builds instructions
def build_instructions
  next_ram = 16
  @asm.each do |asm_inst|
    if asm_inst[0] == "@"
      if asm_inst[1] =~ /[0-9]/
        instruction = asm_inst[1..-1].to_i.to_s(2).rjust(16, "0")
      elsif @symbol_table.has_key?(asm_inst[1..-1].to_sym)
        # instruction = "0" * 16
        instruction = @symbol_table[asm_inst[1..-1].to_sym]
      else
        @symbol_table.store(asm_inst[1..-1].to_sym, "%016b" % next_ram)
        next_ram += 1
        instruction = @symbol_table[asm_inst[1..-1].to_sym]
      end
    elsif asm_inst[0] == "("
      instruction = nil # @symbol_table[asm_inst.delete("()")]
    elsif /;/ =~ asm_inst
      instruction = "0" * 16
      instruction[0..3] = "1110"
      instruction[4..9] = gen_comp(asm_inst[0])
      instruction[13..15] = gen_jump_cond(asm_inst.strip[-3..-1])
    elsif /=/ =~ asm_inst
      instruction = "0" * 16
      instruction[0..3] = /M/.match(asm_inst.split('=')[1]) ? "1111" : "1110"
      instruction[4..9] = gen_comp(/=(.+)/.match(asm_inst.strip)[1])
      instruction[10..12] = gen_dest(/.*?[^=]*/.match(asm_inst.strip)[0])
    else
      instruction = asm_inst
    end
    if !instruction.nil? && (instruction.length != 16)
      puts asm_inst
      puts instruction
    end
    @hack.puts instruction if instruction
  end
end

# First pass to build symbol table
def assign_pseudocommands
  rom_address = 0
  @asm.each do |asm_line|
    if asm_line[0] == "("
      @symbol_table.store(asm_line.delete('()').strip.to_sym, ("%016b" % rom_address))
    end
    rom_address += 1 unless asm_line[0] == "("
  end
end

initialize_environment
populate_predefined_symbols
assign_pseudocommands
build_instructions
@hack.close
