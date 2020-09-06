module Static

export serve

using LiveServer
using ..Types
using ..Parse
using ..Write
using ..BuildTools
using ..BuildTools: skipfile

function serve(p::String=pwd(); kwargs...)
    serve(parse_slide(p); kwargs...)
end

function serve(p::Presentation; kwargs...)
    build_dir = build(p)
    raw_files = collect_files(p)
    assets = assets_files(p)
    # TODO: update file sets
    function reload_slide(fp)
        # TODO: only build changed file
        if fp in assets
            @info "asset $fp changed, update asset"
            cp(fp, joinpath(build_dir, fp); force=true)
        end

        if fp in raw_files
            @info "content $fp changed, recompile index.html"
            write(joinpath(build_dir, "index.html"), parse_slide(p.path))
        end

        LiveServer.file_changed_callback(fp)
    end

    fw = LiveServer.SimpleWatcher(reload_slide)

    for file in raw_files
        LiveServer.watch_file!(fw, file)
    end

    for file in assets
        LiveServer.watch_file!(fw, file)
    end

    return LiveServer.serve(fw; dir=build_dir, kwargs...)
end

function collect_files(p::Presentation)
    if p.standalone
        return [p.path]
    else
        files = [p.path]
        for slide in p.slides
            append!(files, collect_files(slide))
        end
        return unique(files)
    end
end

collect_files(p::BasicSlide) = [p.path]

function collect_files(p::SectionSlide)
    files = [p.path]
    for slide in p.slides
        append!(files, collect_files(slide))
    end

    return unique(files)
end

function assets_files(p::Presentation)
    p.standalone && return []

    files = []
    for dir in readdir(p.path)
        if !startswith(dir, "_") && !startswith(dir, ".") && !skipfile(dir)
            if isfile(dir)
                push!(files, dir)
            else
                for (root, dirs, files) in walkdir(dir)
                    for file in files
                        push!(files, joinpath(root, file))
                    end
                end
            end
        end
    end
    return files
end

end
