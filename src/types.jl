module Types

using CommonMark
export BasicSlide, SectionSlide, SlideView, Presentation, AbstractSlide
export meta, segment

abstract type AbstractSlide end

struct BasicSlide <: AbstractSlide
    meta::Union{Dict, Nothing}
    path::String
    root::CommonMark.Node
end

struct SectionSlide <: AbstractSlide
    meta::Union{Dict, Nothing}
    path::String
    slides::Vector{BasicSlide}
end

struct Presentation
    meta::Union{Dict, Nothing}
    path::String
    slides::Vector{AbstractSlide}
    standalone::Bool
end

meta(x::AbstractSlide) = x.meta
meta(x::Presentation) = x.meta

function Base.show(io::IO, m::MIME"text/plain", x::BasicSlide, env=Dict{String,Any}())
    # printstyled(io, "Slide:\n\n"; bold=true)
    show(io, m, x.root, env)
    return
end

function Base.show(io::IO, m::MIME"text/plain", x::SectionSlide, env=Dict{String,Any}())
    printstyled(io, "Section:\n\n"; bold=true)
    print_slides(io, m, x.slides, env, "---")
    return
end

function Base.show(io::IO, m::MIME"text/plain", x::Presentation, env=Dict{String,Any}())
    printstyled(io, "Presentation:\n\n"; bold=true)

    if haskey(x.meta, "authors")
        printstyled(io, "authors: ", join(x.meta["authors"], ", "))
        println(io, "\n")
    end

    printstyled(io, "="^(displaysize()[2]÷2); color=:light_black)
    println(io, "\n")
    print_slides(io, m, x.slides, env, "="^(displaysize()[2]÷2))
    return
end

function print_slides(io::IO, m::MIME"text/plain", slides, env, div="---")
    for (k, slide) in enumerate(slides)
        show(io, m, slide, env)

        if k != length(slides)
            println(io)
            printstyled(io, div * "\n\n"; color=:light_black)
        end
    end
end

end
