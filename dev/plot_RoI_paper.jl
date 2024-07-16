# This script is used to plot the manually saved RoI on the SR image by executing the individual sections given below. 
# Then the histogram of z values within the RoI is plotted by clicking the hist button.
include("FigRoI_paper.jl")

#======================================================================================================#
manual_polygon_points = [Point2f0(510.66107, 420.85706), Point2f0(542.4695, 391.33902), Point2f0(617.68994, 474.3986), Point2f0(593.38184, 502.08063), Point2f0(510.66107, 420.85706)]
draw_Roi(manual_polygon_points)

#======================================================================================================#
z_range = (quantile(loc_data["z"], 0.01), quantile(loc_data["z"], 0.99))
manual_polygon_points = [Point2f0(1883.1887, 394.58356), Point2f0(1954.8966, 341.46667), Point2f0(1982.214, 379.40747), Point2f0(1913.9205, 440.1125), Point2f0(1883.1887, 394.58356)]
draw_Roi(manual_polygon_points)

#======================================================================================================#
z_range = (quantile(loc_data["z"], 0.01), quantile(loc_data["z"], 0.99))
manual_polygon_points = [Point2f0(), Point2f0(), Point2f0(), Point2f0(), Point2f0()]
draw_Roi(manual_polygon_points)











# To index out:
# subout = out[550:1140, 480:1600]