def initialize_environment
  # Use argument as assembly file to process
  asm_file = ARGV[0]

  # Extract path for output file
  path = /^.*\./.match(asm_file)

  # Setup globals
  @asm = IO.readlines(asm_file)
  @hack = File.open("#{path}hack", "w")
  @address = nil

  # Strip comments and black lines from instructions
  @asm.select! { |line| /\S/ =~ line && /^(\/\/).*/ !~ line}
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
  @asm.each { |asm_inst|
    if asm_inst[0] == "@"
      instruction = asm_inst[1..-1].to_i.to_s(2).rjust(16, "0")
#      @address = instruction[1..15]
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
    @hack.puts instruction
  }
end

initialize_environment
build_instructions
@hack.close
