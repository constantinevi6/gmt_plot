#!/usr/bin/env python3

import pygmt
import laspy
import math
import numpy as np
import copy
import datetime
import yaml
import sys
import os
import multiprocessing
import chardet
import time
#import matplotlib.pyplot as plt
from collections import OrderedDict
from osgeo import gdal
from osgeo import osr
from pathlib import Path
#from obspy import UTCDateTime

Version = "2.1.0"

def represent_dictionary_order(self, dict_data):
    return self.represent_mapping('tag:yaml.org,2002:map', dict_data.items())

def setup_yaml():
    yaml.add_representer(OrderedDict, represent_dictionary_order)   

def detectEncode(DataInput):
    rawdata = open(DataInput, "rb").read()
    result = chardet.detect(rawdata)
    Encode = result['encoding']
    return Encode

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

def read_GNSS(File, Header = 0):

    with open(File,'r') as fh:
        Content = fh.read()
        ContentLine = Content.split('\n')
    GNSS = [
        "",                               # GNSS Station Name
        np.empty((0),dtype=float),        # NEU Reference position (WGS84)
        np.empty((0),dtype="datetime64"), # Year, month, day for the given position epoch
        np.empty((0),dtype=np.str_),      # Hour, minute, second for the given position epoch
        np.empty((0),dtype=float),        # Modified Julian day for the given position epoch
        np.empty((0),dtype=float),        # X coordinate
        np.empty((0),dtype=float),        # Y coordinate
        np.empty((0),dtype=float),        # Z coordinate
        np.empty((0),dtype=float),        # Standard deviation of the X position, meters
        np.empty((0),dtype=float),        # Standard deviation of the Y position, meters
        np.empty((0),dtype=float),        # Standard deviation of the Z position, meters
        np.empty((0),dtype=float),        # Correlation of the X and Y position
        np.empty((0),dtype=float),        # Correlation of the X and Z position
        np.empty((0),dtype=float),        # Correlation of the Y and Z position
        np.empty((0),dtype=float),        # Latitude
        np.empty((0),dtype=float),        # Longitude
        np.empty((0),dtype=float),        # Height relative to WGS-84 ellipsoid, m
        np.empty((0),dtype=float),        # Difference in North component from NEU reference position, meters
        np.empty((0),dtype=float),        # Difference in East component from NEU reference position, meters
        np.empty((0),dtype=float),        # Difference in vertical component from NEU reference position, meters
        np.empty((0),dtype=float),        # Standard deviation of dN, meters
        np.empty((0),dtype=float),        # Standard deviation of dE, meters
        np.empty((0),dtype=float),        # Standard deviation of dU, meters
        np.empty((0),dtype=float),        # Correlation of dN and dE
        np.empty((0),dtype=float),        # Correlation of dN and dU
        np.empty((0),dtype=float),        # Correlation of dE and dU
        np.empty((0),dtype=np.str_)       # "rapid", "final", "suppl/suppf", "campd", or "repro" corresponding to products generated with rapid or final orbit products, in supplemental processing, campaign data processing or reprocessing
    ]
    GNSS[0] = ContentLine[3].split(":")[1].split()[0]
    Position = ContentLine[8].split(":")[1].split()
    Position = Position[0:3]
    GNSS[1] = np.array(Position)
    for DataLine in ContentLine[Header:len(ContentLine)-1]:
        Data = np.array(DataLine.split())
        for i in range(0,21):
            Record = 0
            if i == 0:
                dt = datetime.datetime.strptime(Data[i], "%Y%m%d")
                Record = np.array(str(dt.strftime("%Y-%m-%d")),dtype="datetime64")
            elif i == 1 or i == 21:
                Record = np.array(Data[i],dtype=np.str_)
            else:
                Record = np.array(Data[i],dtype=float)
            GNSS[i + 2] = np.append(GNSS[i + 2],Record)
        
    return GNSS

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

def getRange(Dataset, Mirror = False, Fit = False):
    if np.issubdtype(Dataset.dtype, np.datetime64):
        Range_Min = Dataset[0].astype(datetime.datetime)
        Range_Min = Range_Min.replace(day=1)
        Range_Max = Dataset[len(Dataset) - 1].astype(datetime.datetime)
        newMonth = (Range_Max.month -1 + 1) % 12 + 1
        Range_Max = Range_Max.replace(month=newMonth, day=1)
        return [Range_Min.strftime("%Y-%m-%d"), Range_Max.strftime("%Y-%m-%d")]
    else:
        if Fit:
            Range_Min = Dataset.min()
            Range_Max = Dataset.max()
        elif not Mirror:
            Value_Min = abs(Dataset.min())
            Value_Max = abs(Dataset.max())
            Range_Min = -math.ceil(Value_Min/(10**(math.floor(math.log10(Value_Min)))))*(10**(math.floor(math.log10(Value_Min))))
            Range_Max = math.ceil(Value_Max/(10**(math.floor(math.log10(Value_Max)))))*(10**(math.floor(math.log10(Value_Max))))
        else:
            Value_Max = max(abs(Dataset.min()),abs(Dataset.max()))
            Range_Max = math.ceil(Value_Max/(10**(math.floor(math.log10(Value_Max)))))*(10**(math.floor(math.log10(Value_Max))))
            Range_Min = -Range_Max
        return [Range_Min, Range_Max]

def help_info():
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

def config_io(config, Type="custom", Batch=False, Layer=[], Input=[], Output="", Format="png", Transparent=True, Width=0, Hight=0, SubPlotX=1, Margins=1, Unit="c", Additional=[""]):
    config["IO"] = {
        "Type": Type,
        "Batch": Batch,
        "Layer": Layer,
        "Input": Input,
        "Output": Output,
        "Format": Format,
        "Transparent": Transparent,
        "Plot Width": Width,
        "Plot Hight": Hight,
        "Plots Per Row": SubPlotX,
        "Margins": Margins,
        "Margins Unit": Unit,
        "Additional Plot": Additional
        }

def config_basemap(config, Left=0, Right=0, Lower=0, Upper=0, Projection="X", Width=0, Hight=0, Unit="c", FrameStyle="plain", Frame="WSen", Bax=0, Bfx=0, Bxg=False, Bay=0, Bfy=0, Byg=False, X_Label="", Y_Label="", X_Offset=0, Y_Offset=0):
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
        "File Path": str(Data_Path),
        "Type": Type,
        "Crop": Crop,
        "Output": Output,
        "CPT": CPT,
        "CPT Range": Range,
        "Shade": False,
        }

def config_xy(LayerID, config, Plot=True, Data_Path="",TS=False, Value=None, Size=0.02, Type="c", Pen="", Fill="", CPT="jet", Range=[float(0)]):
    config["Layer"+str(LayerID)] = {
        "Layer": "psxy",
        "Plot": Plot,
        "File Path": str(Data_Path),
        "Time Series": TS,
        "Value": Value,
        "Size": float(Size),
        "Type": Type,
        "Pen": Pen,
        "Fill": Fill,
        "CPT": CPT,
        "CPT Range": Range,
        }

def config_colorbar(LayerID, config, Plot=True, Link=0, Position="BC", Position_Offset_X=0, Position_Offset_Y=0, Width=10, Hight=0.5, Unit="c", Anchor="TC", Direction="h", X_Offset=0, Y_Offset=0, Label="", Ba=50, Bf=10, BoxColor="white", BoxTrans=30, CPT="jet", CPT_Range=[0]):
    if Link != 0:
        CPT = config["Layer"+str(Link)]["CPT"]
        CPT_Range = copy.deepcopy(config["Layer"+str(Link)]["CPT Range"])
    config["Layer"+str(LayerID)] = {
        "Layer": "colorbar",
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
        "Box Color": BoxColor,
        "Box Transparency": BoxTrans,
        "CPT": CPT,
        "CPT Range": CPT_Range
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

def config_text(LayerID, config, Plot=True, Text="", Position_X=None, Position_Y=None, Position="TL", Position_Offset_X=0, Position_Offset_Y=0, Font="Times-Roman", FontSize="16p", FontColor="black", Justify="BL", Angle=0, Clearance="", Fill=None, Pen=None, NoClip=False, Transparency=0, Wrap=None, X_Offset=0, Y_Offset=0):
    config["Layer"+str(LayerID)] = {
        "Layer": "text",
        "Plot": Plot,
        "Text": Text,
        "Position X": Position_X,
        "Position Y": Position_Y,
        "Position": Position,
        "Position X Offset": Position_Offset_X,
        "Position Y Offset": Position_Offset_Y,
        "Font": Font,
        "Font Size": FontSize,
        "Font Color": FontColor,
        "Justify": Justify,
        "Angle": Angle,
        "Clearance": Clearance,
        "Fill": Fill,
        "Pen": Pen,
        "NoClip": NoClip,
        "Transparency": Transparency,
        "Wrap": Wrap,
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

def config_PSV(config, Input=""):
    DataInput = Path(Input)
    if len(Input) == 0:
        CPT_Range = [0, 0]
        dataset = np.zeros([3,1])
    else:
        dataset = read_laz(DataInput)
        CPT_Range = getRange(dataset[2], True)
    CPT_Range.append(0.01)
    NLayer = 0
    config_basemap(config, float(np.round(min(dataset[0]),4)), float(np.round(max(dataset[0]),4)), float(np.round(min(dataset[1]),4)), float(np.round(max(dataset[1]),4)), "M", 15, 0, "c", "fancy")
    NLayer += 1
    config_image(NLayer, config)
    NLayer += 1
    config_xy(NLayer, config, True, DataInput, False, None, 0.02, "c", "", "cpt", "jet", CPT_Range)
    Link = NLayer
    NLayer += 1
    config_colorbar(NLayer, config, True, Link, "TL", 0.5, 0.5, 6, 0.5, "c", "TL", "v", 1, -1, "LOS Velocity (mm/year)", max(CPT_Range), 10)
    NLayer += 1
    config_compass(NLayer, config, True, "LT", 0.5, 0.5, 1, 0, "c", 0, 0)
    NLayer += 1
    config_scale(NLayer, config, True, "RB", 0.5, 0.5, 10, "e", "t", 0, 0)
    NLayer += 1

def config_PSTS(config):
    DataInput = Path(f".")
    ListData = []
    ListDate = np.empty(0,dtype="datetime64")
    for itData in os.listdir(DataInput):
        pathData = Path(itData)
        if (len(pathData.stem) == 8) & (pathData.suffix == ".laz"):
            dt = datetime.datetime.strptime(pathData.stem, "%Y%m%d")
            Date = np.array(str(dt.strftime("%Y-%m-%d")),dtype="datetime64")
            ListDate = np.append(ListDate,Date)
            ListData.append(pathData)
    ListDate.sort()
    ListData.sort()
    dataset = read_laz(ListData[len(ListData) - 1])
    Range_X = getRange(ListDate)
    Range_Y = getRange(dataset[2],True) 
    NLayer = 0
    config_basemap(config, Range_X[0], Range_X[1], Range_Y[0], Range_Y[1], "X", 18, 8, "c", "plain", "WSen", 0, 0, False, 0, 10, True, "Time", "LOS Displacement(mm)")
    NLayer += 1
    config_xy(NLayer, config, False, DataInput, True, "Isolate", 0.1, "c", "", "", "categorical", [0])
    NLayer += 1
    config_xy(NLayer, config, True, DataInput, True, "Mean", 0.16, "c", "", "black", "", [0])
    NLayer += 1
    config_text(NLayer, config, True, "Lontitude:   ", None, None, "TL", 0.5, -0.5, "Times-Roman", "10p", "black", "BL", 0)
    NLayer += 1
    config_text(NLayer, config, True, "Latitude:    ", None, None, "TL", 0.5, -1, "Times-Roman", "10p", "black", "BL", 0)
    NLayer += 1
    config_text(NLayer, config, True, "Picked PSs:  ", None, None, "TL", 0.5, -1.5, "Times-Roman", "10p", "black", "BL", 0)

def config_GNSS(config, NPlot):
    Color=["red", "green", "blue"]
    YLable=["Latitude (mm)", "Longitude (mm)", "Heigh (mm)"]
    NLayer = 0
    if NPlot == 2:
        config_basemap(config, 0, 0, -0, 0, "X", 18, 8, "c", "plain", "WSen", 0, 0, False, 0, 10, True, "Time", YLable[NPlot], 0, -10)
    else:
        config_basemap(config, 0, 0, -0, 0, "X", 18, 8, "c", "plain", "Wsen", 0, 0, False, 0, 10, True, "", YLable[NPlot], 0, -10)
    NLayer += 1
    config_xy(NLayer, config, True, "", True, None, 0.1, "c", "", Color[NPlot], "", [0])
    if NPlot == 0:
        NLayer += 1
        config_text(NLayer, config, True, "GNSS Station: ", None, None, "TL", 0.5, -0.5, "Times-Roman", "10p", "black", "BL", 0)
        NLayer += 1
        config_text(NLayer, config, True, "Lontitude:    ", None, None, "TL", 0.5, -1, "Times-Roman", "10p", "black", "BL", 0)
        NLayer += 1
        config_text(NLayer, config, True, "Latitude:     ", None, None, "TL", 0.5, -1.5, "Times-Roman", "10p", "black", "BL", 0)

def config_generate(Path_config, Type):
    Config = {}
    config_io(Config, Type, Output="GMTPlot_" + Type)
    if Type == "map":
        Plot = {}
        config_basemap(Plot)
        config_image(Plot)
        config_colorbar(Plot)
        config_compass(Plot)
        config_scale(Plot)
        Config["Plot1"] = Plot
    elif Type == "ts":
        Plot = {}
        config_basemap(Plot)
        config_xy(Plot)
        Config["Plot1"] = Plot
    elif Type == "psv":
        Plot = {}
        config_PSV(Plot, "ps_mean_v.laz")
        Config["Plot1"] = Plot
    elif Type == "psts":
        config_io(Config, Type, True, ["Layer1","Layer2"], [], "GMTPlot_" + Type, "png", True, 0, 0, 1, 1, "c",["pygmt_config_psmask.yml"])
        Plot = {}
        config_PSTS(Plot)
        Config["Plot1"] = Plot
    elif Type == "gps":
        config_io(Config, Type, False, [], [], "GMTPlot_" + Type, "png", True, 0, 0, 1, 1, "c")
        for i in range(0,2):
            Plot = {}
            NPlot = "Plot" + str(i + 1)
            config_GNSS(Plot, i)
            Config[NPlot] = Plot
    else:
        config_basemap(Plot)
        config_image(Plot)
        config_xy(Plot)
        config_colorbar(Plot)
        config_compass(Plot)
        config_scale(Plot)
        Config["Plot1"] = Plot
        
    print(f"Please setup {Path_config} for input.")
    # Save
    with open(Path_config, "w") as f:
        yaml.dump(Config, f, Dumper=yaml.CDumper, sort_keys=False)

def config_load(Type="", Path_config=""):
    ListType = ["map", "ts", "psv", "psd", "psts", "s0", "bl", "gps", "gpsv", "gpsl", "custom"]
    Config = {}
    if Type in ListType:
        if Path_config == "":
            Path_config = Path(f"pygmt_config_{Type}.yml")
        else:
            Path_config = Path(Path_config)
    else:
        Path_config = Path(Type)
    
    if not Path_config.exists():
        if Type in ListType:
            config_generate(Path_config, Type)
        else:
            print("Error: Unsupport plot type.")
        exit(0)
    else:
        print(f"Read config from file {Path_config}.")
        with open(Path_config, 'r') as f:
            Config = yaml.full_load(f)
    return Config

# 繪製框架
def plot_basemap(fig, Layer, Offset_X=0, Offset_Y=0):
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
    if (Offset_X == 0) and (Offset_Y == 0):
        Offset_X = Layer['Map X Offset']
        Offset_Y = Layer['Map Y Offset']
    if Offset_X != 0:
        Offset_X = str(Offset_X) + Unit
        fig.shift_origin(xshift=Offset_X)
    if Offset_Y != 0:
        Offset_Y = str(Offset_Y) + Unit
        fig.shift_origin(yshift=Offset_Y)
    
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
    with pygmt.config(MAP_FRAME_TYPE=FrameStyle, FORMAT_GEO_MAP="ddd.xxF"):
        fig.basemap(frame=Frame)

# 繪製網格物件
def plot_img(fig, Layer, Left, Right, Lower, Upper):
    Input = Layer['File Path']
    Type = Layer['Type']
    CMap = Layer['CPT']
    Series = Layer['CPT Range']
    Shade = Layer['Shade']
    Crop = Layer['Crop']
    Output = Layer['Output']
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
def plot_xy(fig,  Layer, Dataset = 0):
    Input = Layer['File Path']
    TS = Layer['Time Series']
    Value = Layer['Value']
    Size = Layer['Size']
    Type = Layer['Type']
    Pen = Layer['Pen']
    Fill = Layer['Fill']
    CMap = Layer['CPT']
    Series = Layer['CPT Range']
    if Dataset != 0:
        dataset = Dataset
    elif (Path(Input).suffix == ".las") | (Path(Input).suffix == ".laz"):
        dataset = read_laz(Path(Input))
    elif Path(Input).suffix == ".csv":
        Delimier = ","
        Encode = detectEncode(Path(Input))
        dataset = np.loadtxt(Input,dtype="str",delimiter=Delimier,encoding=Encode)
        dataset = dataset.transpose()
    else:
        Delimier = None
        Encode = None
        dataset = np.loadtxt(Input,dtype="str",delimiter=Delimier,encoding=Encode)
        dataset = dataset.transpose()

    if TS:
        X = np.array(dataset[0],dtype="datetime64")
    else:
        X = np.array(dataset[0],dtype="float")

    if Value == None:
        Y = np.array([dataset[1]],dtype="float")
    elif Value == "Sum":
        Y = np.array([sum(np.array(dataset[1:len(dataset)],dtype="float"))])
    elif Value == "Mean":
        Y = np.array([np.mean(np.array(dataset[1:len(dataset)],dtype="float"),axis=0)])
    elif Value == "Isolate":
        Y = np.array(dataset[1:len(dataset)])
    else:
        Y = np.array([dataset[Value]])

    if len(dataset) < 3:
        Z = np.zeros(X.size)
    elif Value == "Isolate":
        Z = np.arange(len(dataset)-1)
    else:
        Z = np.array(dataset[2])

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
    elif Fill == None:
        CMap = None
    elif len(Fill) != 0:
        CMap = None
    for it in range(0,len(Y)):
        fig.plot(x=X,y=Y[it],style=Style,pen=Pen,size=Size,cmap=CMap,color=Fill)

def plot_colorbar(
        fig,
        Layer,
        LinkLayer=0
):
    Position = Layer['Position']
    Position_X_Offset = Layer['Position X Offset']
    Position_Y_Offset = Layer['Position Y Offset']
    Width = Layer['Width']
    Hight = Layer['Hight']
    Unit = Layer['Unit']
    Anchor = Layer['Anchor']
    Direction = Layer['Direction']
    Label = Layer['Label']
    Ba = Layer['Ba']
    Bf = Layer['Bf']
    Box_Color = Layer['Box Color']
    Box_Transparency = Layer['Box Transparency']
    CMap = Layer["CPT"]
    Series = Layer["CPT Range"]
    if LinkLayer != 0:
        CMap = LinkLayer["CPT"]
        Series = LinkLayer["CPT Range"]
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

    Position = "j" + Position
    Position = Position + "+o" + str(Position_X_Offset) + Unit
    Position = Position + "/" + str(Position_Y_Offset) + Unit
    if (Width != 0):
        Position = Position + "+w" + str(Width) + Unit
    if (Hight != 0):
         Position = Position + "/" + str(Hight) + Unit
    Position = Position + "+" + Direction + "+j" + Anchor
    
    Box = "+g" + Box_Color + "@" + str(Box_Transparency) + "+r"

    pygmt.makecpt(cmap=CMap, series=Series)
    fig.colorbar(
        position = Position,
        frame    = Frame, 
        cmap     = True,
        box      = Box
    )

def plot_text(fig, Layer):
    Text = Layer['Text']
    Position_X = Layer['Position X']
    Position_Y = Layer['Position Y']
    Position = Layer['Position']
    Position_Offset_X = Layer['Position X Offset']
    Position_Offset_Y = Layer['Position Y Offset']
    Font = Layer['Font']
    FontSize = Layer['Font Size']
    FontColor = Layer['Font Color']
    Justify= Layer['Justify']
    Angle= Layer['Angle']
    Clearance= Layer['Clearance']
    Fill= Layer['Fill']
    Pen= Layer['Pen']
    NoClip= Layer['NoClip']
    Transparency= Layer['Transparency']
    Wrap= Layer['Wrap']
    Offset_X= Layer['X Offset']
    Offset_Y= Layer['Y Offset']

    if (Position_X != None) and (Position_Y != None):
        Position = None
        Position_Offset_X = 0
        Position_Offset_Y = 0
    Offset = str(Position_Offset_X) + "c/" + str(Position_Offset_Y) + "c"
    Font = FontSize + "," + Font + "," + FontColor
    if len(Clearance) == 0:
        Clearance = None
    fig.text(text=Text,x=Position_X,y=Position_Y,position=Position,offset=Offset,font=Font,justify=Justify,angle=Angle,clearance=Clearance,fill=Fill,pen=Pen,no_clip=NoClip,transparency=Transparency,wrap=Wrap,xshift=Offset_X,yshift=Offset_Y)

def get_psts(config, ListConfig, ArrPS, Range = 1):
    DataInput = Path(".")
    ListData = []
    for itData in os.listdir(DataInput):
        pathData = Path(itData)
        if (len(pathData.stem) == 8) & (pathData.suffix == ".laz"):
            ListData.append(DataInput/pathData)
    ListData.sort()
    PS_Pick = []
    ListOutput = []
    dataset = read_laz(ListData[0])
    for PS in ArrPS:
        Lon = PS[0]
        Lat = PS[1]
        Output = config["IO"]["Output"] + "_" + str(format(Lon, '.5f')) + "_" + str(format(Lat, '.6f'))
        Pick = (dataset[0]>Lon-m2lon(PS, Range)) & (dataset[0]<Lon+m2lon(PS, Range)) & (dataset[1]>Lat-m2lat(PS, Range)) & (dataset[1]<Lat+m2lat(PS, Range))
        PS_Pick.append(Pick)
        ListOutput.append(Output)
        if any(Pick):
            print(f"Find {sum(Pick)} PS within {Range} meter(s) around {Lon}, {Lat}")
        else:
            print(f"Can't find PS within {Range} meter(s) around {Lon}, {Lat}")
    del dataset
    ListPSData = [np.empty((0))] * len(ArrPS)
    ListPS = [np.empty((0))] * len(ArrPS)
    for itData in range(0,len(ListData)):
        itDS = read_laz(ListData[itData])
        for itPS in range(0,len(ArrPS)):
            if any(PS_Pick[itPS]):
                if itData == 0:
                    Lon = itDS[0, PS_Pick[itPS]]
                    Lat = itDS[1, PS_Pick[itPS]]
                    ListPS[itPS] = np.append([Lon], [Lat], axis=0)
                    ListPSData[itPS] = [itDS[2, PS_Pick[itPS]]]
                else:
                    ListPSData[itPS] = np.append(ListPSData[itPS], [itDS[2, PS_Pick[itPS]]], axis=0)
    
    AdditionPlots = config["IO"]["Additional Plot"]
    if len(AdditionPlots[0]) == 0:
        AdditionPlots[0] = "pygmt_config_psmask.yml"
        configFile = Path("pygmt_config_psv.yml")
        if not configFile.exists():
            config_generate(configFile, "psv")
        configMask = config_load(configFile)
        configMask["IO"]["Output"] = "GMTPlot_psts"
        Plot = configMask["Plot1"]
        for itLayer in Plot:
            Layer = Plot[itLayer]
            if itLayer == "Layer2":
                Layer["Fill"] = None
                Layer["Pen"] = "2p,yellow"
            else:
                Layer["Plot"] = False
        with open(AdditionPlots[0], "w") as f:
            yaml.dump(configMask, f, Dumper=yaml.CDumper, sort_keys=False)
        
    ListInput = []
    ListMaskConfig = []
    ListTask = []
    for itPS in range(0,len(ArrPS)):
        if any(PS_Pick[itPS]):
            itconfig = copy.deepcopy(config)
            PS = ArrPS[itPS]
            Lon = PS[0]
            Lat = PS[1]
            itconfig["IO"]["Output"] = itconfig["IO"]["Output"] + "_" + str(format(Lon, '.5f')) + "_" + str(format(Lat, '.6f'))
            FileData = itconfig["IO"]["Output"] + ".txt"
            FilePS = itconfig["IO"]["Output"] + "_selected.txt"
            for nPlot in itconfig:
                if nPlot == "IO":
                    continue
                Plot = itconfig[nPlot]
                for nLayer in Plot:
                    Layer = Plot[nLayer]
                    if Layer['Layer'] == "text":
                        if Layer['Text'].find("Lontitude") == 0:
                            Layer['Text'] = "Lontitude:   " + str(format(Lon, '.5f'))
                        if Layer['Text'].find("Latitude") == 0:
                            Layer['Text'] = "Latitude:      " + str(format(Lat, '.6f'))
                        if Layer['Text'].find("Picked") == 0:
                            Layer['Text'] = "Picked PSs: " + str(np.count_nonzero(PS_Pick[itPS]))
            PSData = ListPSData[itPS]
            FileOutputStream = open(FileData, 'w')
            for itDate in range(0,len(ListData)):
                dt = datetime.datetime.strptime(ListData[itDate].stem, "%Y%m%d")
                FileOutputStream.write('%s ' % str(dt.strftime("%Y-%m-%d")))
                for itSelected in range(0, len(PSData[itDate])):
                    FileOutputStream.write('%s ' % PSData[itDate][itSelected])
                FileOutputStream.write('\n')
            FileOutputStream.close()
            ListInput.append([FileData])
            np.savetxt(FilePS, ListPS[itPS].transpose(), fmt="%3.8f")
            ListConfig.append(itconfig)

            configFile = Path(AdditionPlots[0])
            print(f"Create mask for PS: {Lon} {Lat}.")
            configMask = config_load(configFile)
            configMask["IO"]["Output"] = configMask["IO"]["Output"] + "_" + str(format(Lon, '.5f')) + "_" + str(format(Lat, '.6f')) + "_mask"
            configMask["Plot1"]["Layer2"]["File Path"] = FilePS
            ListTask.append(multiprocessing.Process(target=plot, args=(copy.deepcopy(configMask),)))
    parallelTask(ListTask)
    for Task in ListTask:
        Task.join()
    return ListInput

def plot_gps(configGPS, GNSSDataset):
    return 0

def plot(config):
    Type = config["IO"]["Type"]
    Input = config["IO"]["Input"]
    Batch = config["IO"]["Batch"]
    Plot_Width = config["IO"]["Plot Width"]
    Plot_Hight = config["IO"]["Plot Hight"]
    PlotsROWS = config["IO"]["Plots Per Row"]
    Margins = config["IO"]["Margins"]
    MarginsUnit = config["IO"]["Margins Unit"]
    NPlot = len(Input)
    if (NPlot == 0):
        NPlot = 1
    fig = pygmt.Figure()
    pygmt.config(FONT="Times-Roman")
    if Type == "psts":
        pygmt.config(MAP_GRID_PEN_PRIMARY="thinnest,-")
    for it in range(0,NPlot):
        NCOL = (it + 1)  % PlotsROWS
        if NCOL != 0:
            ShiftX = Plot_Width + Margins
            ShiftY = 0
        else:
            ShiftX = (Plot_Width + Margins) * (PlotsROWS - 1)
            ShiftY = -(Plot_Hight + Margins)
        for iPlot in config:
            if iPlot == "IO":
                continue
            Plot = config[iPlot]
            plot_basemap(fig, Plot['basemap'])
            for iLayer in Plot:
                Layer = Plot[iLayer]
                if iLayer in config["IO"]["Layer"]:
                    Layer["File Path"] = config["IO"]["Input"][it]

                if Layer['Layer'] == "grdimage":
                    if not Layer['Plot']:
                        continue
                    plot_img(fig, Layer, Plot["basemap"]["Edge Left"], Plot["basemap"]["Edge Right"], Plot["basemap"]["Edge Lower"], Plot["basemap"]["Edge Upper"])
                elif Layer['Layer'] == "psxy":
                    if not Layer['Plot']:
                        continue
                    Dataset = 0
                    plot_xy(fig, Layer, Dataset)
                elif Layer['Layer'] == "colorbar":
                    if not Layer['Plot']:
                        continue
                    plot_colorbar(fig, Layer, Plot[Layer['Link']])
                elif Layer['Layer'] == "text":
                    plot_text(fig, Layer)

            plot_Frame(fig, Plot['basemap'])

        ShiftX = str(ShiftX) + MarginsUnit
        ShiftY = str(ShiftY) + MarginsUnit
        fig.shift_origin(xshift=ShiftX,yshift=ShiftY)

    # fig.show()
    Output = config['IO']['Output']
    if Batch:
        InputName = Path(Input[0]).stem
        Output = Output + InputName.replace(Output,"")
    Output = Output + "." + config['IO']['Format']
    fig.savefig(Output, transparent=config['IO']['Transparent'])

def parallelTask(ListTask):
    TaskCount = 0
    for Task in ListTask:
        Task.start()
        TaskCount = TaskCount + 1
        if TaskCount == 16:
            # time.sleep(5)
            TaskCount = 0

def main():
    print(f"pyGMT plot Version: {Version} by Constantine VI.")
    config = {}
    setup_yaml()
    if len(sys.argv) < 2:
        help_info()
    elif sys.argv[1] == "help":
        help_info()
    else:
        if len(sys.argv) == 2:
            config = config_load(sys.argv[1])
        else:
            config = config_load(sys.argv[1], sys.argv[2])

    ListInput = []
    ListConfig = []

    if config["IO"]["Type"] == "psts":
        if len(sys.argv) == 2:
            print("No input for PS time series plot, exiting.")
            exit(0)
        elif Path(sys.argv[2]).is_file():
            print("PS time series plot for selected points.")
            ArrPS = np.genfromtxt(Path(sys.argv[2]), delimiter=',')
            if len(sys.argv) >= 4:
                Range = float(sys.argv[3])
            else:
                Range = 1.0
        elif len(sys.argv) >= 4:
            try:
                Lon = float(sys.argv[2])
                Lat = float(sys.argv[3])
                if len(sys.argv) == 5:
                    Range = float(sys.argv[4])
                else:
                    Range = 1.0
                ArrPS = np.array([(Lon, Lat, Range)])
                print(f"PS time series plot for single point: {Lon}, {Lat}.")
            except ValueError:
                print("Input is not a coordinate of a single point.")
        ListInput = get_psts(config, ListConfig, ArrPS, Range)

    elif sys.argv[1] == "gps":
        if len(sys.argv) > 3:
            ListInput = sys.argv[3:len(sys.argv)]
        else:
            ListInput = []
    
        ListTask = []
        for InputFile in ListInput:
            configGPS = copy.deepcopy(config)
            GNSSDataset = read_GNSS(InputFile, 37)
            configGPS["Plot1"]["IO"]["Ouput Name"] = configGPS["Plot1"]["IO"]["Ouput Name"] + "_" + GNSSDataset[0]
            Range_X_Min = GNSSDataset[2][0].astype(datetime.datetime)
            Range_X_Min = Range_X_Min.replace(day=1)
            Range_X_Max = GNSSDataset[2][len(GNSSDataset[2]) - 1].astype(datetime.datetime)
            newMonth = (Range_X_Max.month -1 + 1) % 12 + 1
            Range_X_Max = Range_X_Max.replace(month=newMonth, day=1)
            for i in range(0,2):
                NPlot = "Plot" + str(i + 1)
                Max_Y = max(abs(GNSSDataset[i + 17].min()),abs(GNSSDataset[i + 17].max()))
                Range_Y = math.ceil(Max_Y/(10**(math.floor(math.log10(Max_Y)))))*(10**(math.floor(math.log10(Max_Y))))
                configGPS[NPlot]["basemap"]["Edge Left"] = Range_X_Min
                configGPS[NPlot]["basemap"]["Edge Right"] = Range_X_Max
                configGPS[NPlot]["basemap"]["Edge Lower"] = -Range_Y
                configGPS[NPlot]["basemap"]["Edge Upper"] = Range_Y
                if i == 0:
                    for Layer in configGPS[NPlot]:
                        if Layer["Layer"] == "text":
                            if Layer['Text'].find("GNSS Station") != -1:
                                Layer['Text'] = "GNSS Station:   " + GNSSDataset[0]
                            if Layer['Text'].find("Lontitude") != -1:
                                Layer['Text'] = "Lontitude:   " + GNSSDataset[1][1]
                            if Layer['Text'].find("Latitude") != -1:
                                Layer['Text'] = "Latitude:      " + GNSSDataset[1][0]
            ListTask.append(multiprocessing.Process(target=plot_gps, args=(configGPS, GNSSDataset)))
    else:
        if len(sys.argv) > 2:
            for it in range(2,len(sys.argv)):
                ListInput.append([sys.argv[it]])
                ListConfig.append(copy.deepcopy(config))
        else:
            ListInput = [[0]]
            ListConfig.append(copy.deepcopy(config))
    ListTask = []
    for it in range(0,len(ListInput)):
        ListConfig[it]["IO"]["Input"] = ListInput[it]
        ListTask.append(multiprocessing.Process(target=plot, args=(ListConfig[it],)))
    parallelTask(ListTask)
    for Task in ListTask:
        Task.join()

# Main
if __name__=='__main__':
    start = time.time()
    main()
    print("pyGMT plot finish.")
    end = time.time()
    print(f"Used time: {format(end - start, '.2f')}s")