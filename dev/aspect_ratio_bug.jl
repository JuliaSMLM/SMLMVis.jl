using Revise
using SMLMVis
using SMLMData


# MWE that breaks:
nlocs = 1000
sz_x = 10
sz_y = 2
σ_big = 10
smld = SMLMData.SMLD2D(nlocs)
smld.x = rand(nlocs)*sz_x
smld.y = rand(nlocs)*sz_y
smld.σ_x = ones(nlocs)
smld.σ_y = ones(nlocs)
smld.datasize = [sz_y, sz_x] # large aspect ratio breaks the rendering
out2, (cm, z_range) = SMLMVis.render_blobs(smld; zoom = 100)
display(out2)



# Testing physical Arrays 

import SMLMVis.GaussRender: PhysicalArray, physical_value, index_value

a = PhysicalArray(1:.3:10,3:.4:30)


a[1,1]

a[1.0,2.2]


a[1.0,2.6] = 10.0

index_value(a, 1.0, 2.9)
physical_value(a, 1, 2)

b = a[2:4, 3:5]

a[2.0:4.0, 3.0:5.0] .= 4
