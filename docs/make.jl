using SMLMVis
using Documenter

#DocMeta.setdocmeta!(SMLMVis, :DocTestSetup, :(using SMLMVis); recursive=true)

makedocs(;
    modules=[SMLMVis],
    authors="klidke@unm.edu",
    repo="https://github.com/JuliaSMLM/SMLMVis.jl/blob/{commit}{path}#{line}",
    sitename="SMLMVis.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaSMLM.github.io/SMLMVis.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Blob Rendering" => "blob_rendering.md",
    ],
    warnonly=true,
)

deploydocs(;
    repo="github.com/JuliaSMLM/SMLMVis.jl",
    devbranch="main",
)
