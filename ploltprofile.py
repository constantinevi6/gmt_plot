import pygmt
import numpy as np
import laspy
from pathlib import Path
def read_laz(DataInput):
    if not DataInput.exists():
        print(f"Data file {DataInput} not found.")
        exit(0)
    with laspy.open(DataInput) as fh:
        las = fh.read()
        ground_pts = las.classification == 2
        bins, counts = np.unique(las.return_number[ground_pts], return_counts=True)
        fh.close()
    dataset = np.array((las.x, las.y, las.z))
    return dataset

Data=read_laz(Path("ps_mean_v.laz"))

profile = pygmt.project(
    data=Data,
    center=[121.57, 24.03],
    endpoint=[121.65, 23.98],
    # unit=True會將 p, q 之單位設定為公里，否則原本單位會統一(應該是"度")
    unit=True,
    length='w',
    # unit=True之後這裡單位也會是公里
    width=[-0.25, 0.25],

)

fig = pygmt.Figure()
fig.plot(
    x=profile[3],
    y=profile[2],
    # 利用"點"來進行繪製
    style="c0.1c",
    # 點的顏色設定為黑色
    color="black",
    region=[min(profile[3]), max(profile[3]), -50, 50],
    projection="X15c/6c",
    frame=["xa1f0.5+lDistence (km)","ya50f10+lLOS Velocity (mm/year)","WSne"]
)
fig.show()