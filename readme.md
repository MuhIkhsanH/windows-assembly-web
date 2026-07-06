nasm -f win64 -o web.obj web.asm

gcc web.obj -o web.exe -lws2_32
