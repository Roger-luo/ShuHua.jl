module Parse

export parse_slide
using CommonMark
using Pkg
using ..Types

const TOML_NAME = ["JuliaHuan.toml", "Huan.toml"]

function default_features()
    [
        FrontMatterRule(toml=Pkg.TOML.parse),
        FootnoteRule(),
        MathRule(),
        TableRule(),
        RawContentRule(),
        AttributeRule(),
        CitationRule(),
        AutoIdentifierRule(),
        AdmonitionRule(),
    ]
end

function create_parser()
    parser = Parser()
    enable!(parser, default_features())
    return parser
end

function segment(file)
    return open(file) do io
        raw = read(io, String)
        split(raw, "---\n")
    end
end

function default_meta()
    Dict(
        "highlight" => "monokai",
        "theme" => "black",
        "revealjs" => Dict(
            "version" => "4.0.2",
            "path" => "reveal.js",
        )
    )
end

function extract_meta(ast::CommonMark.Node)
    for (node, entering) in ast
        if node.t isa CommonMark.FrontMatter
            return node.t.data
        end
    end
    return
end

function parse_slide(path, parser=create_parser())
    if isfile(path)
        return parse_file(path, parser)
    elseif ispath(path)
        return parse_project(path, parser)
    else
        error("invalid path: $path")
    end
end

function parse_file(filename, parser)
    slides = _parse_file(filename, parser)
    m = merge(default_meta(), meta(first(slides)))
    return Presentation(m, filename, slides, true)
end

function parse_project(path, parser)
    toml = nothing
    for each in TOML_NAME
        if isfile(joinpath(path, each))
            toml = joinpath(path, each)
            break
        end
    end

    toml === nothing && error("please specify meta in $(join(TOML_NAME, " or "))")
    meta = merge(default_meta(), Pkg.TOML.parsefile(toml))

    slides = _parse_file(joinpath(path, "index.md"), parser)
    return Presentation(meta, path, slides, false)
end

function _parse_file(filename, parser)
    return map(segment(filename)) do s
        ast = parser(s)
        meta = extract_meta(ast)

        if meta !== nothing && haskey(meta, "include")
            file = joinpath(dirname(filename), meta["include"])
            isfile(file) || error("$file does not exist!")
            slides = _parse_file(file, parser)
            return SectionSlide(meta, filename, slides)
        else
            return BasicSlide(meta, filename, ast)
        end
    end
end

end
