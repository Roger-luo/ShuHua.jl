module Write

using Mustache
using CommonMark
using ..ShuHua
using ..Types

export html

Base.write(io::IO, p::Presentation) = write(io, html(p))

function CommonMark.html(p::Presentation)
    template = get(p.meta, "template", "basic")
    if isfile(template)
        file = template
    else
        file = ShuHua.project("templates", template * ".html")
        isfile(file) || error("unknown template $template")
    end

    view = copy(p.meta)
    view["slides"] = join(map(html, p.slides), "\n")
    return render_from_file(file, view)
end

function _section(f, x)
    return "<section$(slide_options(x))>$(f(x))</section>"
end

function CommonMark.html(x::BasicSlide)
    return _section(x->CommonMark.html(x.root), x)
end

function CommonMark.html(x::SectionSlide)
    return _section(x) do x::SectionSlide
        join(map(CommonMark.html, x.slides), "\n")
    end
end

slide_options(x::AbstractSlide) = slide_options(x.meta)
slide_options(::Nothing) = ""

const REVEAL_OPTIONS = [
    # transition
    "data-transition",
    "data-transition-speed",
    # background
    "data-background-color",
    "data-background-image",
    "data-background-size",
    "data-background-position",
    "data-background-repeat",
    "data-background-opacity",
    ## background-video
    "data-background-video",
    "data-background-video-loop",
    "data-background-video-muted",
    ## background-iframe
    "data-background-iframe",
    "data-background-interactive",
]

function parse_options(x::Dict)
    options = Dict()

    # forward direct options
    for key in REVEAL_OPTIONS
        if haskey(x, key)
            options[key] = x[key]
        end
    end

    # unfold hierachical options
    if haskey(x, "background")
        if x["background"] isa AbstractDict
            for (k, v) in x["background"]
                key = "data-background-$k"
                if key in REVEAL_OPTIONS
                    options[key] = v
                end
            end
        end
    end
    return options
end

function slide_options(x::Dict)
    isempty(x) && return ""
    # TODO: validate options
    # TODO: support alias
    options = ["$k=\"$v\"" for (k, v) in parse_options(x)]
    return " " * join(options, " ")
end

end
