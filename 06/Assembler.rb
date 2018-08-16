asm_file = ARGV[0]
path = /^.*\./.match(asm_file)
puts asm_file
puts path
asm = IO.readlines(asm_file)
hack = File.open("#{path}hack", "w")
hack.close
