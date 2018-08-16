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
asm.select! { |inst| /\S/ =~ inst && /^(\/\/).*/ !~ inst}

asm.each { |instruction|

}

hack.close
