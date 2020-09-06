module BuildTools

export build

using ..ShuHua
using ..Types
using ..Write

using Pkg.PlatformEngines
const REVEALJS = "https://github.com/hakimel/reveal.js/archive/"

const SKIP_EXTS = [".md", ".toml"]
const IGNORE_PATH = ["build"]

revealjs(version) = ShuHua.project("deps", "reveal.js-" * version)
revealjs_version(p::Presentation) = p.meta["revealjs"]["version"]
revealjs(p::Presentation) = revealjs(revealjs_version(p))

function build(p::Presentation, build_dir::String)
    download_revealjs(revealjs_version(p))

    if p.standalone
        build_file(p, build_dir)
    else
        build_project(p, build_dir)
    end
end

function build(p::Presentation)
    download_revealjs(revealjs_version(p))

    if p.standalone
        build_file(p)
    else
        build_project(p)
    end
end


function download_revealjs(version::String)
    if ispath(revealjs(version))
        return
    end

    url = REVEALJS * version * ".tar.gz"
    tarball = ShuHua.project("deps", version * ".tar.gz")
    ispath(ShuHua.project("deps")) || mkpath(ShuHua.project("deps"))
    download(url, tarball)
    PlatformEngines.probe_platform_engines!()
    unpack(tarball, ShuHua.project("deps"))
    return
end

function build_file(p::Presentation)
    name = splitext(basename(p.path))[1]
    return build_file(p, mktempdir(prefix=name * "_"))
end

function build_project(p::Presentation)
    name = basename(p.path)
    build_dir = joinpath(p.path, "build")
    ispath(build_dir) || mkpath(build_dir)

    return build_project(p, build_dir)
end

function build_project(p::Presentation, build_dir)
    build_file(p, build_dir)
    # copy materials
    for dir in readdir(p.path)
        if !startswith(dir, "_") && !startswith(dir, ".") && !skipfile(dir)
            cp(dir, joinpath(build_dir, dir); force=true)
        end
    end
    return build_dir
end

function build_file(p::Presentation, build_dir)
    path_revealjs = joinpath(build_dir, p.meta["revealjs"]["path"])
    ispath(path_revealjs) || cp(revealjs(p), path_revealjs)
    write(joinpath(build_dir, "index.html"), p)
    return build_dir
end

function skipfile(file)
    file in IGNORE_PATH && return true

    return any(SKIP_EXTS) do ext
        endswith(file, ext)
    end
end

end
