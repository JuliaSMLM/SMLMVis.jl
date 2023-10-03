using Revise
using SMLMSim
using SMLMData
using Images
using SMLMVis

# 2D
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
save("nmer2d.png", out)

# 3D
smld_true, smld_model, smld_noisy = SMLMSim.sim(;
    ρ=10,
    σ_PSF=[0.13, 0.13, 0.3],  
    minphotons=50,
    ndatasets=10,
    nframes=1000,
    framerate=50.0, 
    pattern=SMLMSim.Nmer3D(),
    molecule=SMLMSim.GenericFluor(; q=[0 50; 1e-2 0]), #1/s 
    camera=SMLMSim.IdealCamera(; ypixels=256, xpixels=128, pixelsize=0.1)
    ) 


out = render_blobs(smld_noisy; zoom = 20)
save("nmer3d.png", out)



