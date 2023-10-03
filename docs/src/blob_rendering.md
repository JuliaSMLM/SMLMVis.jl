```@meta
CurrentModule = SMLMVis.GaussRender
DocTestSetup = quote
    using SMLMVis
end
```

# SMLMVis.GaussRender

## Overview

```@docs
GaussRender
```

## Basic Usage

### Rendering 2D SMLM Images

2D SMLM images will render with the `hot` colormap by default.  

```@example
using SMLMVis
using SMLMSim
using Images

smld_true, smld_model, smld_noisy = SMLMSim.sim(;
    ρ=10,
    σ_PSF=0.13,  
    minphotons=50,
    ndatasets=10,
    nframes=1000,
    framerate=50.0, 
    pattern=SMLMSim.Nmer2D(),
    molecule=SMLMSim.GenericFluor(; q=[0 50; 1e-2 0]), #1/s 
    camera=SMLMSim.IdealCamera(; ypixels=32, xpixels=64, pixelsize=0.1)
    ) 

out = render_blobs(smld_noisy; zoom = 20)
save("nmer2d.png", out) # hide
```

```@raw html
<img src="nmer2d.png" alt="nmer2d.png" width="600"/>
```

### Rendering 3D Images

3D SMLM images will render with a rainbow colormap by default. 
```@example
using SMLMVis
using SMLMSim
using Images

smld_true, smld_model, smld_noisy = SMLMSim.sim(;
    ρ=10,
    σ_PSF=[0.13, 0.13, 0.3],  
    minphotons=50,
    ndatasets=10,
    nframes=1000,
    framerate=50.0, 
    pattern=SMLMSim.Nmer3D(),
    molecule=SMLMSim.GenericFluor(; q=[0 50; 1e-2 0]), #1/s 
    camera=SMLMSim.IdealCamera(; ypixels=32, xpixels=64, pixelsize=0.1)
    ) 

out = render_blobs(smld_noisy; zoom = 20)
save("nmer3d.png", out) # hide
```

```@raw html
<img src="nmer3d.png" alt="nmer3d.png" width="600"/>
```

## API

```@index
Modules = [GaussRender]
```

```@autodocs
Modules = [GaussRender]
```