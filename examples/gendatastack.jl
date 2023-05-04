using Revise
using SMLMDeepFit
DF=SMLMDeepFit
using MicroscopePSFs
PSF=MicroscopePSFs
using Images

# Making PSF 
na=1.2
n=1.3
λ=.6
pixelsize=.1

mag=[1.0]
phase=zeros(6)
phase[6]=1 #osa index 5 -astigmatism
z=PSF.ZernikeCoefficients(mag,phase)
psf=PSF.Scalar3D(na,λ,n,pixelsize;z=z)

# Save PSF
psfdir = "C:\\Users\\lidkelab\\Documents\\MATLAB\\SMLMVis.jl\\examples\\temp\\psfs"
isdir(psfdir) || mkdir(psfdir)
psf_fn = "psf_zernike.jld2"
PSF.save(joinpath(psfdir, psf_fn), psf)


# Generate Data
data,y=DF.gendata(;ρ=1.0,sz=128,nframes=100,bg=5.0,maxz=1.0,photons=500.0,readnoise=0.7,psffile="C:\\Users\\lidkelab\\Documents\\MATLAB\\SMLMVis.jl\\examples\\temp\\psfs\\psf_zernike.jld2")
#data,y=DF.gendata(psf;ρ=1.0,sz=128,nframes=100,bg=5.0,maxz=1.0,photons=500.0,rmsee=0.7)

# Look at a few frames
imzoom=4 #(interpolated)

for i in 1:4
    display(imresize(Gray.(DF.scaleim(data[:,:,1,i])),ratio=imzoom))
end

for i in 1:6
    display(imresize(Gray.(y[:,:,i,1]),ratio=imzoom))
end











