with open('flutter_minnalearn/lib/data/kanji_stroke_dictionary.dart', 'r', encoding='utf-8') as f:
    content = f.read()

n4_chars = list(dict.fromkeys(list('験試貸借終始開閉集別思知引押落拾止歩走起持待送使作考教習勉強研究音楽歌画写真旅世界特急便利不親切好意味理飯肉鳥牛物語朝昼夜夕方洗運動転通降着去院館堂屋場室工質問題答宿顔頭心病薬死医者体声配番号員都市町')))

found = []
missing = []
for c in n4_chars:
    needle = "'" + c + "': const KanjiStrokeData"
    if needle in content:
        found.append(c)
    else:
        missing.append(c)

print(f"Total Unique N4: {len(n4_chars)}")
print(f"Found in Stroke Dict: {len(found)}")
print(f"Missing in Stroke Dict: {len(missing)}")
print("Missing characters:", "".join(missing))
