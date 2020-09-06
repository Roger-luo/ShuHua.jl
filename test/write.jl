using ShuHua
using ShuHua.Parse
using ShuHua.Write

pr = parse_slide(ShuHua.project("example", "simple.md"))
pr.meta
html(pr)
write("index.html", pr)
pr = parse_slide(ShuHua.project("example", "huan"))
html(pr)
using ShuHua.BuildTools

pr.meta
build(pr)

