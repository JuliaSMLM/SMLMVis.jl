```@meta
CurrentModule = SMLMVis.MIC
DocTestSetup = quote
    using SMLMVis
end
```

# SMLMVis.MIC

## Overview

```@docs
MIC
```

## Basic Usage

### Process one file using several keyword options
```julia
using SMLMVis

dirname = "C:/Data"
filename = "CellMovie"
fn = joinpath(dirname, filename * ".h5")

mic2mp4(fn; fps = 20, percentilerange = 0.99, zoom = 4, frame_range = 1:100)

```

### Process a directory 

```julia
using SMLMVis

dirname = "C:/Data"

# A little julia ...
files = filter(f -> endswith(f, ".h5"), readdir(dirname))
fullpathfiles = dirname .* "/" .* files

# Use broadcasting over the file names
mic2mp4.(fullpathfiles; fps = 20, percentilerange = 0.99)
```

### The first 50 frames in all datasets

```julia
using SMLMVis

dirname = "C:/Data"
savedir = "C:/Data/Results"
filename = "CellMovie"
fn = joinpath(dirname, filename * ".h5")

# Use comprehension over datasets and put results a different folder
n = SMLMVis.MIC.count_datasets(fn)
[mic2mp4(fn; savedir=savedir, fps=20, percentilerange=0.99, datasetnum=i, frame_range=1:50) for i in 1:n];
```




## API

```@index
Modules = [MIC]
```

```@autodocs
Modules = [MIC]
```