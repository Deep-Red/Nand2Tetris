# Use argument as assembly file to process
asm_file = ARGV[0]

# Extract path for output file
path = /^.*\./.match(asm_file)

# Debug Line
puts asm_file

# Setup for input and output
asm = IO.readlines(asm_file)
hack = File.open("#{path}hack", "w")

# Strip comments and black lines from instructions
asm.select! { |line| /\S/ =~ line && /^(\/\/).*/ !~ line}

# Sets last three bits for jump condition
def set_jump_cond(cond)
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

# Builds instructions
asm.each { |asm_inst|
  puts asm_inst
  puts asm_inst[0]
  if asm_inst[0] == "@"
    instruction = asm_inst[1..-1].to_i.to_s(2).rjust(16, "0")
  elsif /;/ =~ asm_inst
    instruction[13..14] = set_jump_cond(asm_inst[-3..-1])
    instruction[]
  else
    instruction = asm_inst
  end
  hack.puts instruction
}

hack.close
