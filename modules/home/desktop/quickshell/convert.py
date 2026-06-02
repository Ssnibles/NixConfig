cp = int("UF001", 16)  # paste the codepoint from the cheat sheet here
if cp > 0xFFFF:
    hs = 0xD800 + ((cp - 0x10000) >> 10)
    ls = 0xDC00 + ((cp - 0x10000) & 0x3FF)
    print(f'"\\u{hs:04X}\\u{ls:04X}"')
else:
    print(f'"\\u{cp:04X}"')
