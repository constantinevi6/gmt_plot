#!/usr/bin/env python3

import pygmt
import laspy
import math
import numpy as np
from pathlib import Path
import matplotlib.pyplot as plt
#from obspy import UTCDateTime
import datetime
import yaml
import sys
import os
from collections import OrderedDict
from osgeo import gdal
from osgeo import osr
import copy

def represent_dictionary_order(self, dict_data):
    return self.represent_mapping('tag:yaml.org,2002:map', dict_data.items())

def setup_yaml():
    yaml.add_representer(OrderedDict, represent_dictionary_order)   

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

def ll2m(P1, P2):
    # Radius of earth in m
    R = 6378137 
    dLat = P2[1] * math.pi / 180 - P1[1] * math.pi / 180;
    dLon = P2[0] * math.pi / 180 - P1[0] * math.pi / 180;
    a = math.sin(dLat/2) * math.sin(dLat/2) + math.cos(P1[1] * math.pi / 180) * math.cos(P2[1] * math.pi / 180) * math.sin(dLon/2) * math.sin(dLon/2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    d = R * c
    return d

def m2lat(P, Radius):
    R = 6378317
    dLat = (Radius / R) * (180 / math.pi)
    return abs(dLat)

def m2lon(P, Radius):
    R = 6378317
    dLon = (Radius / R) * (180 / math.pi) / math.cos(P[1] * math.pi / 180);
    return abs(dLon)

def help_info():
    print("")
    print("pyGMT plot script by Constantine VI.")
    print("")
    print("Support mode:")
    print("    map:  just a simple map.")
    print("    ts:   time series from input file.")
    print("    psv:  map contain mean velocity of PSInSAR.")
    print("    psd:  time series of map contain deformation of PSInSAR.")
    print("    psts: time series of deformation of single PS.")
    print("    s0:   time series of Sigma naught of single pixel in SAR image stack.")
    print("    bl:   baseline plot of InSAR image pairs.")
    print("    gps:  time series of deformation in ENU of single GNSS station.")
    print("    gpsv: map contain GNSS mean velocity in ENU of single GNSS station.")
    print("    gpsl: time series of deformation project to SAR LOS of single GNSS station.")
    
def config_general(config, Ouput_Name="", Format="PNG", Transparent=True, Left=0, Right=0, Lower=0, Upper=0, Projection="X", Width=0, Hight=0, Unit="c", FrameStyle="plain", Frame="WSen", Bax=0, Bfx=0, Bxg=False, Bay=0, Bfy=0, Byg=False, X_Label="", Y_Label="", X_Offset=0, Y_Offset=0):
    config["IO"] = {
        "Layer": "IO",
        "Ouput Name": Ouput_Name,
        "Figure Format": Format,
        "Figure Transparent": Transparent,
        }
    config["basemap"] = {
        "Layer": "basemap",
        "Edge Left": Left,
        "Edge Right": Right,
        "Edge Lower": Lower,
        "Edge Upper": Upper,
        "Projection": Projection,
        "Map Width": float(Width),
        "Map Hight": float(Hight),
        "Map Unit": Unit,
        "Map Frame Style": FrameStyle,
        "Map Frame": Frame,
        "Map X Label": X_Label,
        "Map Y Label": Y_Label,
        "Map Bax": float(Bax),
        "Map Bfx": float(Bfx),
        "Map Grid X": Bxg,
        "Map Bay": float(Bay),
        "Map Bfy": float(Bfy),
        "Map Grid Y": Byg,
        "Map X Offset": float(X_Offset),
        "Map Y Offset": float(Y_Offset),
        }

def config_image(LayerID, config, Plot=True, Data_Path="", Type="Auto", Crop=True, Output="Basemap_crop", CPT="Auto", Range=[float(0)]):
    config["Layer"+str(LayerID)] = {
        "Layer": "grdimage",
        "Plot": Plot,
        "Image Path": str(Data_Path),
        "Image Type": Type,
        "Image Crop": Crop,
        "Image Output": Output,
        "Image CPT": CPT,
        "Image CPT Range": Range,
        "Image Shade": False,
        }

def config_xy(LayerID, config, Plot=True, Data_Path="",TS = False, Size=0.02, Type="c", Pen="", Fill="", CPT="jet", Range=[float(0)]):
    config["Layer"+str(LayerID)] = {
        "Layer": "psxy",
        "Plot": Plot,
        "Data Path": str(Data_Path),
        "Time Series": TS,
        "Size": float(Size),
        "Type": Type,
        "Pen": Pen,
        "Fill": Fill,
        "CPT": CPT,
        "CPT Range": Range,
        }

def config_colorbar(LayerID, config, Plot=True, Link="", Position="BC", Position_Offset_X=0, Position_Offset_Y=0, Width=10, Hight=0.5, Unit="c", Anchor="TC", Direction="h", X_Offset=0, Y_Offset=0, Label="", Ba=50, Bf=10):
    config["Layer"+str(LayerID)] = {
        "Layer": "psscale",
        "Plot": Plot,
        "Link": "Layer"+str(Link),
        "Position": Position,
        "Position X Offset": Position_Offset_X,
        "Position Y Offset": Position_Offset_Y,
        "Width": float(Width),
        "Hight": float(Hight),
        "Unit": Unit,
        "Anchor": Anchor,
        "Direction": Direction,
        "X Offset": float(X_Offset),
        "Y Offset": float(Y_Offset),
        "Label": Label,
        "Ba": float(Ba),
        "Bf": float(Bf),
        }

def config_compass(LayerID, config, Plot=False, Position="LT", Position_Offset_X=0, Position_Offset_Y=0, Width=2, Hight=0, Unit="c", X_Offset=1, Y_Offset=2):
    config["Layer"+str(LayerID)] = {
        "Layer": "compass",
        "Plot": Plot,
        "Position": Position,
        "Position X Offset": Position_Offset_X,
        "Position Y Offset": Position_Offset_Y,
        "Width": float(Width),
        "Hight": float(Hight),
        "Unit": Unit,
        "X Offset": float(X_Offset),
        "Y Offset": float(Y_Offset),
        }

def config_scale(LayerID, config, Plot=True, Position="RB", Position_Offset_X=0, Position_Offset_Y=0, Length=10, Unit="e", Align="t", X_Offset=1, Y_Offset=1):
    config["Layer"+str(LayerID)] = {
        "Layer": "scale",
        "Plot": Plot,
        "Position": Position,
        "Position X Offset": Position_Offset_X,
        "Position Y Offset": Position_Offset_Y,
        "Length": float(Length),
        "Unit": Unit,
        "Align": Align,
        "X Offset": float(X_Offset),
        "Y Offset": float(Y_Offset),
        }

def config_PSV(config):
    DataInput = Path(f"ps_mean_v.laz")
    dataset = read_laz(DataInput)
    Value_CPT = math.ceil(max(abs(dataset[2].min()),abs(dataset[2].max()))/10)*10

    NLayer = 0
    config_general(config, "GMTPlot_PSV", "PNG", True, float(np.round(min(dataset[0]),4)), float(np.round(max(dataset[0]),4)), float(np.round(min(dataset[1]),4)), float(np.round(max(dataset[1]),4)), "M", 15, 0, "c", "fancy")
    NLayer += 1
    config_image(NLayer, config)
    NLayer += 1
    config_xy(NLayer, config, True, DataInput, False, 0.02, "c", "", "cpt", "jet", [Value_CPT * (-1), Value_CPT, 0.01])
    Link = NLayer
    NLayer += 1
    config_colorbar(NLayer, config, True, Link, "TL", 0.5, 0.5, 6, 0.5, "c", "TL", "v", 1, -1, "LOS Velocity (mm/year)", Value_CPT, 10)
    NLayer += 1
    config_compass(NLayer, config, True, "LT", 0.5, 0.5, 1, 0, "c", 0, -4)
    NLayer += 1
    config_scale(NLayer, config, True, "RB", 0.5, 0.5, 10, "e", "t", 1, 1)
    NLayer += 1

def config_PSTS(config):
    DataInput = Path(f".")
    ListData = []
    ListDate = []
    for itData in os.listdir(DataInput):
        pathData = Path(itData)
        if (len(pathData.stem) == 8) & (pathData.suffix == ".laz"):
            dt = datetime.datetime.strptime(pathData.stem, "%Y%m%d")
            ListDate.append(dt)
            ListData.append(pathData)
    ListDate.sort()
    ListData.sort()
    dataset = read_laz(ListData[len(ListData) - 1])
    Range_Y = math.ceil(max(abs(dataset[2].min()),abs(dataset[2].max()))/10 + 1)*10
    Range_X_Min = ListDate[0]
    Range_X_Min = Range_X_Min.replace(day=1)
    Range_X_Max = ListDate[len(ListDate) - 1]
    newMonth = (ListDate[len(ListDate) - 1].month -1 + 1) % 12 + 1
    Range_X_Max = Range_X_Max.replace(month=newMonth, day=1)
    NLayer = 0
    config_general(config, "GMTPlot_PSTS", "PNG", True, Range_X_Min, Range_X_Max, -Range_Y, Range_Y, "X", 18, 8, "c", "plain")
    NLayer += 1
    config_xy(NLayer, config, True, DataInput,True, 0.2, "c", "", "black")

def config_generate(config, Path_config, Type):
    Plot = {}
    if Type == "map":
        config_general(config, "GMTPlot_Map")
        config_image(config)
        config_colorbar(config)
        config_compass(config)
        config_scale(config)
        Plot["Plot1"] = config
    elif Type == "ts":
        config_general(config, "GMTPlot_TS")
        config_xy(config)
        Plot["Plot1"] = config
    elif Type == "psv":
        config_PSV(config)
        Plot["Plot1"] = config
    elif Type == "psts":
        config_PSTS(config)
        Plot["Plot1"] = config
    else:
        config_general(config)
        config_image(config)
        config_xy(config)
        config_colorbar(config)
        config_compass(config)
        config_scale(config)
        Plot["Plot1"] = config
        
    print(f"Please setup {Path_config} for input.")
    # Save
    with open(Path_config, "w") as f:
        yaml.dump(Plot, f, Dumper=yaml.CDumper, sort_keys=False)

def config_load(Type="", Path_config=""):
    if Path_config == "":
        Path_config = Path(f"pygmt_config_{Type}.yml")
    else:
        Path_config = Path(Path_config)
    config = {}
    if not Path_config.exists():
        config_generate(config, Path_config, Type)
        exit(0)
    else:
        with open(Path_config, 'r') as f:
            config = yaml.full_load(f)
    return config

# 繪製框架
def plot_basemap(fig, Layer):
    Left = Layer['Edge Left']
    Right = Layer['Edge Right']
    Lower = Layer['Edge Lower']
    Upper = Layer['Edge Upper']
    Projection = Layer['Projection']
    Width = Layer['Map Width']
    Hight = Layer['Map Hight']
    Unit = Layer['Map Unit']
    FrameStyle="plain"
    Frame="wsen"
    Transparency=99

    if Projection == "X":
        Projection = Projection + str(Width) + Unit + "/" + str(Hight) + Unit
    else:
        Projection = Projection + str(Width) + Unit

    Region = [Left, Right, Lower, Upper]
    Frame = [Frame]
    with pygmt.config(MAP_FRAME_TYPE=FrameStyle):
        fig.basemap(region=Region, projection=Projection, frame=Frame, transparency=Transparency)

# 繪製海岸線
def plot_coast(
        fig,
        Input,
        Shorelines="default,black",
        Water=True,
        Land=False
    ):
    if Water == False:
        arg_water=""
    if Land == True:
        arg_land=""
    fig.coast(
        grid       = Input,
        cmap       = True
    )

# 繪製地圖框線
def plot_Frame(fig, Layer):
    FrameStyle = Layer['Map Frame Style']
    Frame = Layer['Map Frame']
    X_Label = Layer['Map X Label']
    Y_Label = Layer['Map Y Label']
    Bax = Layer['Map Bax']
    Bfx = Layer['Map Bfx']
    Bxg = Layer['Map Grid X']
    Bay = Layer['Map Bay']
    Bfy = Layer['Map Bfy']
    Byg = Layer['Map Grid Y']
    X_Offset = Layer['Map X Offset']
    Y_Offset = Layer['Map Y Offset']

    print("Plotting Frame....")
    Frame = [Frame]
    if Bax != 0:
        Bax=str(Bax)
    else:
        Bax=""
    if Bfx != 0:
        Bfx=str(Bfx)
    else:
        Bfx=""
    if Bxg:
        Bxg = "g"
    else:
        Bxg = ""

    Frame_X = "xa" + Bax + "f" + Bxg + Bfx
    if len(X_Label) != 0:
        Frame_X = Frame_X + "+l" + "\"" + X_Label + "\""
    Frame.append(Frame_X)

    if Bay != 0:
        Bay=str(Bay)
    else:
        Bay=""
    if Bfy != 0:
        Bfy=str(Bfy)
    else:
        Bfy=""
    if Byg:
        Byg = "g"
    else:
        Byg = ""
    Frame_Y = "ya" + Bay + "f" + Byg + Bfy

    if len(Y_Label) != 0:
        Frame_Y = Frame_Y + "+l" + "\"" + Y_Label + "\""
    Frame.append(Frame_Y)

    with pygmt.config(MAP_FRAME_TYPE = FrameStyle, FORMAT_GEO_MAP="ddd.xxF"):
        fig.basemap(frame=Frame)

# 繪製網格物件
def plot_img(fig, Layer, Left, Right, Lower, Upper):
    Input = Layer['Image Path']
    Type = Layer['Image Type']
    CMap = Layer['Image CPT']
    Series = Layer['Image CPT Range']
    Shade = Layer['Image Shade']
    Crop = Layer['Image Crop']
    Output = Layer['Image Output']
    Path_Grd = Path(Input)
    if not os.path.isfile(Path_Grd):
        print("File: '%s' doesn't exist." % str(Path_Grd))
        return 1
    gdal.UseExceptions()
    hDataset = gdal.Open(str(Path_Grd), gdal.GA_ReadOnly)
    if hDataset is None:
        print("gdalinfo failed - unable to open '%s'." % str(Path_Grd))
        return 1
    pszProjection = hDataset.GetProjectionRef()
    if pszProjection is not None:
        hSRS = osr.SpatialReference()
        if hSRS.ImportFromWkt(pszProjection) == gdal.CE_None:
            CSRName = hSRS.GetName()
            print("Coordinate System is:%s" % CSRName)
        else:
            print("Coordinate System is `%s'" % pszProjection)

    Region = [Left, Right, Lower, Upper]
    if CSRName == "WGS 84":
        extent = 0.0001
    else:
        extent = 1
    Left = Left - extent
    Right = Right + extent
    Lower = Lower - extent
    Upper = Upper + extent
    if Crop:
        if len(Output) != 0:
            Path_Crop = Path(Output + ".tif")
        else:
            Path_Crop = Path("Crop_" + str(Path(Input).stem) + ".tif")
        print(f"Starting crop file {Path_Grd} to {Path_Crop}....")
        gdalcmd = f"gdal_translate -projwin {Left} {Upper} {Right} {Lower} -of GTiff {Path_Grd} {Path_Crop}"
        print(gdalcmd)
        os.system(gdalcmd)
    else:
        Path_Crop = Path_Grd

    if Type == "Auto":
        print(f"Starting detect image type for {str(Path_Crop)} ....")
        if (hDataset.RasterCount == 3) | (hDataset.RasterCount == 4):
            Type = "Optical"
            CMap = None
            print("Optical image detected.")
        else:
            Type = "Raster"
            print("Normal raster detected.")
    elif Type == "Optical":
        CMap = None

    if CMap != None:
        if CMap == "Auto":
            if (Type == "Raster") | (Type == "DEM"):
                CMap = "gray"
            elif Type == "IFG":
                CMap = "cyclic"
            else:
                CMap = "jet"
        else:
            CMap = "jet"

        if Series == [0]:
            print("Starting caculate statistics.")
            hBand = hDataset.GetRasterBand(1)
            stats = hBand.GetStatistics(True, False)
            if (stats[0] == 0) & (stats[1] == 0):
                stats = hBand.GetStatistics(True, True)

            Interval = (stats[1] - stats[0]) / 100
            Series = [stats[0], stats[1], Interval]
            
        pygmt.makecpt(cmap=CMap, series=Series)
        CMap = True

    print("Plotting grd....")
    fig.grdimage(
        grid         = Path_Crop,
        cmap         = CMap,
    )
    
    if Shade & (Type != "Optical"):
        print("Starting plot shade....")
        Grd_Shade = pygmt.grdgradient(grid=Path_Crop, radiance=[270, 30])
        pygmt.makecpt(cmap="gray", series=[-1.5, 0.3, 0.01])
        fig.grdimage(
            grid       = Grd_Shade,
            cmap       = True,
            transparency = 50,
        )

# 繪製點物件
def plot_xy(fig,  Layer):
    Input = Layer['Data Path']
    TS = Layer['Time Series']
    Size = Layer['Size']
    Type = Layer['Type']
    Pen = Layer['Pen']
    Fill = Layer['Fill']
    CMap = Layer['CPT']
    Series = Layer['CPT Range']
    if (Path(Input).suffix == ".las") | (Path(Input).suffix == ".laz"):
        dataset = read_laz(Path(Input))
        X = dataset[0]
        Y = dataset[1]
        Z = dataset[2]
    elif TS:
        X = np.loadtxt(Input,dtype="datetime64",usecols=0)
        Y = np.loadtxt(Input,dtype="float",usecols=1)
        Z = np.zeros(len(X))
    else:
        dataset = np.loadtxt(Path(Input))
        X = dataset[0]
        Y = dataset[1]
        Z = dataset[2]

    if Size == "Data":
        Style = Type + "c"
        if Series != [0]:
            Size = Z * (Series[1] - Series[0]) / (max(Z) - min(Z))
        else:
            Size = Z
    else:
        Style = Type + str(Size) + "c"
        Size = None

    if len(Pen) ==0:
        Pen = None
    
    if Fill == "cpt":
        print(f"Fill set to cpt.")
        if (CMap == "Auto") | (len(CMap) == 0):
            CMap = "jet"
        if Series == [0]:
            Interval = (max(Z) - min(Z)) / 100
            Series = [min(Z), max(Z), Interval]
        pygmt.makecpt(cmap=CMap, series=Series)
        Fill = Z
        CMap = True
    elif len(Fill) != 0:
        CMap = None
        
    fig.plot(x=X,y=Y,style=Style,pen=Pen,size=Size,cmap=CMap,color=Fill)

def plot_psscale(
        fig,
        LinkLayer,
        Position="TL",
        Position_X_Offset=0.5,
        Position_Y_Offset=0.5,
        Width=4.0,
        Hight=0.5,
        Unit="c",
        Anchor="TL",
        Direction="v",
        Label="",
        Ba=0,
        Bf=0,
        X_Offset=1.0,
        Y_Offset=-1.0,
):
    Frame = [""]
    if Ba != 0:
        Ba=str(Ba)
    else:
        Ba=""
    if Bf != 0:
        Bf=str(Bf)
    else:
        Bf=""
    Frame[0] = Frame[0] + "a" + Ba + "f" + Bf
    if len(Label) != 0:
        Frame[0] = Frame[0] + "+l" + "\"" + Label + "\""
    if len(Position) == 0:
        Position = "TL"

    if Position[1] == "R":
        Position_X_Offset = Position_X_Offset + 2

    Justification = Position
    Position = "j" + Position
    Position = Position + "+o" + str(Position_X_Offset) + Unit
    Position = Position + "/" + str(Position_Y_Offset) + Unit
    if (Width != 0):
        Position = Position + "+w" + str(Width) + Unit
    if (Hight != 0):
         Position = Position + "/" + str(Hight) + Unit
    Position = Position + "+" + Direction + "+j" + Justification
    
    CMap = LinkLayer["CPT"]
    Series = LinkLayer["CPT Range"]
    pygmt.makecpt(cmap=CMap, series=Series)
    fig.colorbar(
        position = Position,
        frame    = Frame, 
        cmap     = True,
        box      = '+gwhite@30+r'
    )

def get_psts(config, PS):
    print(f"Plotting PS at {PS[0]}, {PS[1]}")
    Lon=PS[0]
    Lat=PS[1]
    if PS[2] != 0:
        Range = PS[2]
    else:
        Range = 1
    DataInput = Path()
    ListData = []
    PS_TXT = ""
    for nPlot in config:
        Plot = config[nPlot]
        for nLayer in Plot:
            Layer = Plot[nLayer]
            if Layer['Layer'] == "IO":
                Layer['Ouput Name'] = Layer['Ouput Name'] + "_" + str(Lon) + "_" + str(Lat)
            if Layer['Layer'] == "psxy":
                DataInput = Path(Layer['Data Path'])
                for itData in os.listdir(DataInput):
                    pathData = Path(itData)
                    if (len(pathData.stem) == 8) & (pathData.suffix == ".laz"):
                        ListData.append(pathData)
                Layer['Data Path'] = Plot['IO']['Ouput Name'] + ".txt"
                PS_TXT = Plot['IO']['Ouput Name'] + ".txt"

    ListData.sort()
    PS_Pick = []
    dataset = read_laz(ListData[0])
    PS_Pick = (dataset[0]>Lon-m2lon(PS, Range)) & (dataset[0]<Lon+m2lon(PS, Range)) & (dataset[1]>Lat-m2lat(PS, Range)) & (dataset[1]<Lat+m2lat(PS, Range))
    del dataset
    if not any(PS_Pick):
        print(f"Can't find PS within {Range} meter(s) at {PS[0]}, {PS[1]}")
        return False
    
    FileOutputData = open(PS_TXT, 'w')
    for itData in ListData:
        dataset = read_laz(itData)
        dt = datetime.datetime.strptime(itData.stem, "%Y%m%d")
        Data = dataset[:, PS_Pick]
        FileOutputData.write('%s ' % str(dt.strftime("%Y-%m-%d")))
        FileOutputData.write('%s\n' % str(float(np.mean(Data[2]))))
    print(f"Find PS at {Data[0]}, {Data[1]}")
    FileOutputData.close()
    return True

def plot(config):
    for nPlot in config:
        Plot = config[nPlot]
        fig = pygmt.Figure()
        for nLayer in Plot:
            Layer = Plot[nLayer]
            if Layer['Layer'] == "basemap":
                plot_basemap(fig, Layer)
            elif Layer['Layer'] == "grdimage":
                if not Layer['Plot']:
                    continue
                plot_img(fig, Layer, Plot["basemap"]["Edge Left"], Plot["basemap"]["Edge Right"], Plot["basemap"]["Edge Lower"], Plot["basemap"]["Edge Upper"])
            elif Layer['Layer'] == "psxy":
                if not Layer['Plot']:
                    continue
                plot_xy(fig, Layer)
            elif Layer['Layer'] == "psscale":
                if not Layer['Plot']:
                    continue
                plot_psscale(fig, Plot[Layer['Link']],Layer['Position'],Layer['Position X Offset'],Layer['Position Y Offset'],Layer['Width'],Layer['Hight'],Layer['Unit'],Layer['Anchor'],Layer['Direction'],Layer['Label'],Layer['Ba'],Layer['Bf'])
        plot_Frame(fig, Plot['basemap'])
        
        # fig.show()
        fig.savefig(f"{Plot['IO']['Ouput Name']}.png",transparent=True)

# Main
Type = ["help","map", "ts", "psv", "psd", "psts", "s0", "bl", "gps", "gpsv", "gpsl", "custom"]
config = {}
setup_yaml()
if len(sys.argv) < 2:
    help_info()
elif sys.argv[1] in Type:
    if sys.argv[1] == Type[0]:
        help_info()
    else:
        if len(sys.argv) == 2:
            config = config_load(sys.argv[1])
        else:
            config = config_load(sys.argv[1], sys.argv[2])

else:
    print("Error: Unsupport plot type.")
    exit(0)

if sys.argv[1] == "psts":
    if len(sys.argv) == 5:
        get_psts(config, np.array([float(sys.argv[3]), float(sys.argv[4]), 0]))
        plot(config)
        # if isinstance(sys.argv[3],float) & isinstance(sys.argv[4],float):
            
    elif Path(sys.argv[3]).is_file:
        List_PS = np.genfromtxt(Path(sys.argv[3]), delimiter=',')
        for PS in List_PS:
            PS = np.append(PS,0.0)
            configPS = copy.deepcopy(config)
            if get_psts(configPS, PS):
                plot(configPS)
        exit(0)
else:
    plot(config)
