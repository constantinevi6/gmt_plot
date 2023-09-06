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
from pathlib import PurePath
#from obspy import UTCDateTime

Version = "2.3.0"
Debug = False
CurrentPath = Path.cwd()

def represent_dictionary_order(self, dict_data):
    return self.represent_mapping('tag:yaml.org,2002:map', dict_data.items())

def setup_yaml():
    yaml.add_representer(OrderedDict, represent_dictionary_order)   

def codedemo(code):
    if Debug == True:
        for itcode in code:
            print(itcode)

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
    print(f"Reading GNSS data from file: {File}")
    with open(File,'r') as fh:
        Content = fh.read()
        ContentLine = Content.split('\n')
    GNSS = [
        "",                               # GNSS Station Name
        np.empty((0),dtype=float),        # NEU Reference position (WGS84)
        np.empty((0))                     # GNSS data record
        ]
    GNSS[0] = ContentLine[3].split(":")[1].split()[0]
    Position = ContentLine[8].split(":")[1].split()
    Position = Position[0:3]
    GNSS[1] = np.array(Position)
    for i in range(Header, len(ContentLine)-1):
        DataLine = ContentLine[i]
        ArrDataLine = np.array(DataLine.split())
        dt = datetime.datetime.strptime(ArrDataLine[0], "%Y%m%d")
        ArrDataLine[0] = str(dt.strftime("%Y-%m-%d"))
        if i == Header:
            GNSS[2] = np.array([ArrDataLine])
        else:
            GNSS[2]=np.append(GNSS[2], [ArrDataLine], axis=0)
    GNSS[2] = GNSS[2].transpose()
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
        Range_Min = min(Dataset).astype(datetime.datetime)
        Range_Min = Range_Min.replace(day=1)
        Range_Max = max(Dataset).astype(datetime.datetime)
        newMonth = (Range_Max.month % 12) + 1
        newYear = math.floor((Range_Max.month) / 12)
        Range_Max = Range_Max.replace(year=Range_Max.year+newYear, month=newMonth, day=1)
        return [Range_Min, Range_Max]
    else:
        if Fit:
            Range_Min = Dataset.min()
            Range_Max = Dataset.max()
        elif not Mirror:
            Value_Min = abs(Dataset.min())
            Value_Max = abs(Dataset.max())
            if Value_Min == 0:
                Value_Min = -1
            if Value_Max == 0:
                Value_Max = 1
            Range_Min = -math.ceil(Value_Min/(10**(math.floor(math.log10(Value_Min)))))*(10**(math.floor(math.log10(Value_Min))))
            Range_Max = math.ceil(Value_Max/(10**(math.floor(math.log10(Value_Max)))))*(10**(math.floor(math.log10(Value_Max))))
        else:
            Value_Max = max(abs(Dataset.min()),abs(Dataset.max()))
            if Value_Max == 0:
                Value_Max = 1
            Range_Max = math.ceil(Value_Max/(10**(math.floor(math.log10(Value_Max)))))*(10**(math.floor(math.log10(Value_Max))))
            Range_Min = -Range_Max
        return [Range_Min, Range_Max]

def usage():
    print("")
    print("Support mode:")
    print("    map:  just a simple map.")
    print("    ts:   time series from input file.")
    print("    psv:  map contain mean velocity of PSInSAR.")
    print("    psd:  time series of map contain deformation of PSInSAR.")
    print("    psts: time series of deformation of single PS.")
    # print("    s0:   time series of Sigma naught of single pixel in SAR image stack.")
    # print("    bl:   baseline plot of InSAR image pairs.")
    print("    gps:  time series of deformation in ENU of single GNSS station.")
    # print("    gpsv: map contain GNSS mean velocity in ENU of single GNSS station.")
    # print("    gpsl: time series of deformation project to SAR LOS of single GNSS station.")

def config_io(config, Type="custom", Batch=False, Layer=[], Input=[], Output="", Format="png", Transparent=True, Width=0, Hight=0, SubPlotX=1, Margins=1, Unit="c", Additional=[]):
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
        "Nodata": None,
        "Shade": False,
        }

def config_xy(LayerID, config, Plot=True, Data_Path="",TS=False, Value=None, Ratio=1, Size=0.02, Type="c", Pen="", Fill="", CPT="jet", Range=[float(0)]):
    config["Layer"+str(LayerID)] = {
        "Layer": "psxy",
        "Plot": Plot,
        "File Path": str(Data_Path),
        "Time Series": TS,
        "Value": Value,
        "Ratio": Ratio,
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

def config_text(LayerID, config, Plot=True, Text="", Position_X=None, Position_Y=None, Position="TL", Position_Offset_X=0, Position_Offset_Y=0, Font="Times-Roman", FontSize="16p", FontColor="black", Justify="BL", Angle=0, Clearance="", Fill=None, Pen=None, NoClip=False, Transparency=0, Wrap=None):
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

def config_profile(LayerID, config, Plot=False, Data_Path="", Vector_Profile=[],TS=False, Value=None, Ratio=1, Size=0.02, Type="c", Pen="", Fill="", CPT="jet", Range=[float(0)]):
    config["Layer"+str(LayerID)] = {
        "Layer": "profile",
        "Plot": Plot,
        "File Path": str(Data_Path),
        "Time Series": TS,
        "Value": Value,
        "Ratio": Ratio,
        "Size": float(Size),
        "Type": Type,
        "Pen": Pen,
        "Fill": Fill,
        "CPT": CPT,
        "CPT Range": Range,
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
    config_xy(NLayer, config, True, DataInput, False, None, 1, 0.02, "c", "", "cpt", "jet", CPT_Range)
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
    config_xy(NLayer, config, False, DataInput, True, "Isolate", 1, 0.1, "c", "", "", "categorical", [0])
    NLayer += 1
    config_xy(NLayer, config, True, DataInput, True, "Mean", 1, 0.16, "c", "", "black", "", [0])
    NLayer += 1
    config_text(NLayer, config, True, "Lontitude:   ", None, None, "TL", 0.5, -0.5, "Times-Roman", "10p", "black", "BL", 0)
    NLayer += 1
    config_text(NLayer, config, True, "Latitude:    ", None, None, "TL", 0.5, -1, "Times-Roman", "10p", "black", "BL", 0)
    NLayer += 1
    config_text(NLayer, config, True, "Picked PSs:  ", None, None, "TL", 0.5, -1.5, "Times-Roman", "10p", "black", "BL", 0)

def config_GNSS(config, NPlot):
    Fill=["blue", "green", "red"]
    YLable=["Heigh (mm)", "Longitude (mm)", "Latitude (mm)"]
    NLayer = 0
    if NPlot == 0:
        config_basemap(config, 0, 0, -0, 0, "X", 18, 8, "c", "plain", "WSen", 0, 0, False, 0, 0, True, "Time", YLable[NPlot], 0, 8.5)
    else:
        config_basemap(config, 0, 0, -0, 0, "X", 18, 8, "c", "plain", "Wsen", 0, 0, False, 0, 0, True, "", YLable[NPlot], 0, 8.5)
    NLayer += 1
    config_xy(NLayer, config, True, "", True, 17 - NPlot, 1000, 0.1, "c", "", Fill[NPlot], "", [0])
    if NPlot == 2:
        NLayer += 1
        config_text(NLayer, config, True, "GNSS Station: ", None, None, "TL", 0.5, -0.5, "Times-Roman", "10p", "black", "BL", 0)
        NLayer += 1
        config_text(NLayer, config, True, "Lontitude:    ", None, None, "TL", 0.5, -1, "Times-Roman", "10p", "black", "BL", 0)
        NLayer += 1
        config_text(NLayer, config, True, "Latitude:     ", None, None, "TL", 0.5, -1.5, "Times-Roman", "10p", "black", "BL", 0)

def config_PSProfile(config):
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
    config_xy(NLayer, config, False, DataInput, True, "Isolate", 1, 0.1, "c", "", "", "categorical", [0])
    NLayer += 1
    config_xy(NLayer, config, True, DataInput, True, "Mean", 1, 0.16, "c", "", "black", "", [0])
    NLayer += 1
    config_text(NLayer, config, True, "Lontitude:   ", None, None, "TL", 0.5, -0.5, "Times-Roman", "10p", "black", "BL", 0)
    NLayer += 1
    config_text(NLayer, config, True, "Latitude:    ", None, None, "TL", 0.5, -1, "Times-Roman", "10p", "black", "BL", 0)
    NLayer += 1
    config_text(NLayer, config, True, "Picked PSs:  ", None, None, "TL", 0.5, -1.5, "Times-Roman", "10p", "black", "BL", 0)

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
        config_xy(1, Plot, True, "", True, None, 1, 0.16, "c", "", "blue", "", [0])
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
        config_io(Config, Type, True, ["Layer1"], [], "GMTPlot_" + Type, "png", True, 0, 0, 1, 1, "c")
        for i in range(0,3):
            Plot = {}
            NPlot = "Plot" + str(i + 1)
            config_GNSS(Plot, i)
            Config[NPlot] = Plot
    else:
        config_basemap(Plot)
        config_image(1, Plot)
        config_xy(2, Plot)
        config_colorbar(3, Plot)
        config_compass(4, Plot)
        config_scale(5, Plot)
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
def plot_basemap(fig, Layer, Offset_X=0, Offset_Y=0, Code=[]):
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

    Code.append(f"with pygmt.config(MAP_FRAME_TYPE=\"{FrameStyle}\"")
    Code.append(f"    fig.basemap(region={Region}, projection=\"{Projection}\", frame={Frame}, transparency={Transparency})")

# 繪製海岸線
def plot_coast(
        fig,
        Input,
        Shorelines="default,black",
        Water=True,
        Land=False,
        Code=[]
    ):
    if Water == False:
        arg_water=""
    else:
        arg_water="skyblue"
    if Land == True:
        arg_land=""
    if Debug:
        print(f"fig.coast(grid={Input},cmap=True)")
    fig.coast(
        grid       = Input,
        cmap       = True
    )
    Code.append(f"fig.coast(grid=\"{Input}\",cmap=True)")

# 繪製地圖框線
def plot_Frame(fig, Layer, Code=[]):
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
    Code.append(f"with pygmt.config(MAP_FRAME_TYPE=\"{FrameStyle}\", FORMAT_GEO_MAP=\"ddd.xxF\"):")
    Code.append(f"    fig.basemap(frame={Frame})")

# 繪製網格物件
def plot_img(fig, Layer, Left, Right, Lower, Upper, Code=[]):
    Input = Layer['File Path']
    Type = Layer['Type']
    CMap = Layer['CPT']
    Series = Layer['CPT Range']
    Shade = Layer['Shade']
    Crop = Layer['Crop']
    NoData = Layer.get('Nodata', None)
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
            print("Coordinate System is: %s" % CSRName)
        else:
            print("Coordinate System is: '%s'" % pszProjection)

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
        os.system(gdalcmd)
        Code.append(f"os.system(\"{gdalcmd}\")")
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
        Code.append(f"pygmt.makecpt(cmap=\"{CMap}\", series={Series})")
        CMap = True
    if NoData is not None:
        NoData = "+z" + str(NoData)

    print("Plotting grd....")
    fig.grdimage(
        grid         = Path_Crop,
        cmap         = CMap,
        nan_transparent = NoData
    )
    Code.append(f"fig.grdimage(grid=\"{Path_Crop}\",cmap={CMap})")
    if Shade & (Type != "Optical"):
        print("Starting plot shade....")
        Grd_Shade = pygmt.grdgradient(grid=Path_Crop, radiance=[270, 30])
        pygmt.makecpt(cmap="gray", series=[-1.5, 0.3, 0.01])
        fig.grdimage(
            grid       = Grd_Shade,
            cmap       = True,
            transparency = 50,
        )
        Grd_Shade.close()
        Code.append(f"Grd_Shade = pygmt.grdgradient(grid=\"{Path_Crop}\", radiance=[270, 30])")
        Code.append(f"pygmt.makecpt(cmap=\"gray\", series=[-1.5, 0.3, 0.01])")
        Code.append(f"fig.grdimage(grid=Grd_Shade,cmap=True,transparency=50)")
        Code.append(f"Grd_Shade.close()")

# 繪製向量物件
def plot_xy(fig,  Layer, Dataset = 0, Code=[]):
    Input = Layer['File Path']
    TS = Layer['Time Series']
    Value = Layer['Value']
    NoData = Layer.get('Nodata', None)
    Ratio = Layer['Ratio']
    Size = Layer['Size']
    Type = Layer['Type']
    Pen = Layer['Pen']
    Fill = Layer['Fill']
    CMap = Layer['CPT']
    Series = Layer['CPT Range']
    if Debug:
        print(type(Input))
    if Dataset != 0:
        dataset = Dataset
    elif type(Input) == np.ndarray:
        dataset = Input
    elif (Path(Input).suffix == ".pos"):
        GNSSData = read_GNSS(Path(Input), 37)
        dataset = GNSSData[2]
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
    if Debug:
        print(dataset)
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
        Y = np.array([dataset[Value]],dtype="float")
    Y = Ratio * Y
    
    if len(dataset) < 3:
        Z = np.zeros(X.size)
    elif Value == "Isolate":
        Z = np.arange(len(dataset)-1)
    else:
        Z = np.array(dataset[2])

    if Type != None:   
        if Size == "Data":
            Style = Type + "c"
            if Series != [0]:
                Size = Z * (Series[1] - Series[0]) / (max(Z) - min(Z))
            else:
                Size = Z
        else:
            Style = Type + str(Size) + "c"
            Size = None
    else:
        Style = None
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
        Code.append(f"pygmt.makecpt(cmap=\"{CMap}\", series={Series})")
        Fill = Z
        CMap = True
    elif Fill == None:
        CMap = None
    elif len(Fill) != 0:
        CMap = None
    for it in range(0,len(Y)):
        fig.plot(x=X,y=Y[it],style=Style,pen=Pen,size=Size,cmap=CMap,fill=Fill,nodata=NoData)
        Code.append(f"X={X}")
        Code.append(f"Y={Y[it]}")
        Code.append(f"fig.plot(x=X,y=Y,style=\"{Style}\",pen=\"{Pen}\",size=\"{Size}\",cmap=\"{CMap}\",fill=\"{Fill}\")")

# 繪製向量物件
def plot_ogr(fig,  Layer, Code=[]):
    Input = Layer['File Path']
    Size = Layer['Size']
    Type = Layer['Type']
    Pen = Layer['Pen']
    Fill = Layer['Fill']
    CMap = Layer['CPT']
    Series = Layer['CPT Range']
    if Debug:
        print(type(Input))

    Input = Path(Input)
    if Input.suffix != ".shp":
        print("Input file is not supported.")
        return
    if Type != None:
        if Size == "Data":
            Style = Type + "c"
        else:
            Style = Type + str(Size) + "c"
            Size = None
    else:
        Style = None
        Size = None

    if len(Pen) ==0:
        Pen = None
    
    if Fill == "cpt":
        print(f"Fill set to cpt.")
        if (CMap == "Auto") | (len(CMap) == 0):
            CMap = "categorical"
        if Series != [0]:
            Series = [0]
        pygmt.makecpt(cmap=CMap, series=Series)
        Code.append(f"pygmt.makecpt(cmap=\"{CMap}\", series={Series})")
        CMap = True
    elif Fill == None:
        CMap = None
    elif len(Fill) != 0:
        CMap = None

    fig.plot(data=Input,style=Style,pen=Pen,size=Size,cmap=CMap,fill=Fill)
    Code.append(f"Data={Input}")
    Code.append(f"fig.plot(data=Data,style=\"{Style}\",pen=\"{Pen}\",size=\"{Size}\",cmap=\"{CMap}\",fill=\"{Fill}\")")

def plot_colorbar(
        fig,
        Layer,
        LinkLayer=0,
        Code=[]
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
    Code.append(f"pygmt.makecpt(cmap=\"{CMap}\", series={Series})")
    Code.append(f"fig.colorbar(position=\"{Position}\",frame={Frame},cmap=True,box=\"{Box}\")")

def plot_text(fig, Layer, Code=[]):
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

    if (Position_X != None) and (Position_Y != None):
        Position = None
        Position_Offset_X = 0
        Position_Offset_Y = 0
    Offset = str(Position_Offset_X) + "c/" + str(Position_Offset_Y) + "c"
    Font = FontSize + "," + Font + "," + FontColor
    if len(Clearance) == 0:
        Clearance = None
    fig.text(text=Text,x=Position_X,y=Position_Y,position=Position,offset=Offset,font=Font,justify=Justify,angle=Angle,clearance=Clearance,fill=Fill,pen=Pen,no_clip=NoClip,transparency=Transparency,wrap=Wrap)
    Code.append(f"fig.text(text=\"{Text}\",x={Position_X},y={Position_Y},position={Position},offset=\"{Offset}\",font=\"{Font}\",justify=\"{Justify}\",angle={Angle},clearance=\"{Clearance}\",fill=\"{Fill}\",pen=\"{Pen}\",no_clip={NoClip},transparency={Transparency},wrap={Wrap})")

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
        
    ListInput = []
    ListAddInput = []
    ListTask = []
    ListArgInput = []
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
            ListAddInput.append([FilePS])
            # configFile = Path(AdditionPlots[0])
            # print(f"Create mask for PS: {Lon} {Lat}.")
            # configMask = config_load(configFile)
            # configMask["IO"]["Output"] = configMask["IO"]["Output"] + "_" + str(format(Lon, '.5f')) + "_" + str(format(Lat, '.6f')) + "_mask"
            # configMask["Plot1"]["Layer2"]["File Path"] = FilePS
            # ArgInput = (copy.deepcopy(configMask),)
            # ListArgInput.append(ArgInput)
    # parallelPool(plot, ListArgInput)

            # ListTask.append(multiprocessing.Process(target=plot, args=(copy.deepcopy(configMask),)))

    AdditionPlots = config["IO"]["Additional Plot"]
    if len(AdditionPlots[0]) == 0:
        AdditionPlots[0] = "pygmt_config_psmask.yml"
    configFile = Path(AdditionPlots[0])
    if not configFile.exists():
        configFilePSV = Path("pygmt_config_psv.yml")
        if configFilePSV.exists():
            configMask = config_load(configFilePSV)
        else:
            config_generate(configFile, "psv")
            configMask = config_load(configFile)

        configMask["IO"]["Batch"] = True
        configMask["IO"]["Layer"] = ["Layer2"]
        configMask["IO"]["Input"] = ListAddInput
        configMask["IO"]["Output"] = "GMTPlot_psmask"
        Plot = configMask["Plot1"]
        for itLayer in Plot:
            Layer = Plot[itLayer]
            if itLayer == "Layer2":
                Layer["Size"] = Layer["Size"] * 1.5
                Layer["Fill"] = None
                Layer["Pen"] = "1p,white"
            else:
                Layer["Plot"] = False
        with open(AdditionPlots[0], "w") as f:
            yaml.dump(configMask, f, Dumper=yaml.CDumper, sort_keys=False)
    # parallelTask(ListTask)
    # for Task in ListTask:
    #     Task.join()
    return ListInput

def get_GNSS_conf(config, it, InputFile, ListConfig, ListInput):
    pygmt._begin()
    ConfigGPS = copy.deepcopy(config)
    GNSSDataset = read_GNSS(InputFile, 37)
    ListInput[it] = [InputFile]
    ConfigGPS["IO"]["Output"] = ConfigGPS["IO"]["Output"] + "_" + GNSSDataset[0]
    ConfigGPS["IO"]["Input"] = [InputFile]
    Range_X = getRange(np.array(GNSSDataset[2][0],dtype="datetime64"))
    Edge_Left = 0
    Edge_Right = 0
    Edge_Lower = 0
    Edge_Upper = 0
    for i in range(0,3): 
        NPlot = "Plot" + str(i + 1)
        Range_Y = getRange(np.array(GNSSDataset[2][17 - i],dtype="float") * ConfigGPS[NPlot]["Layer1"]["Ratio"], True)
        if i == 0:
            if (ConfigGPS[NPlot]["basemap"]["Edge Left"] == 0) and (ConfigGPS[NPlot]["basemap"]["Edge Right"] == 0):
                ConfigGPS[NPlot]["basemap"]["Edge Left"] = Range_X[0]
                ConfigGPS[NPlot]["basemap"]["Edge Right"] = Range_X[1]
            if (ConfigGPS[NPlot]["basemap"]["Edge Lower"] == 0) and (ConfigGPS[NPlot]["basemap"]["Edge Upper"] == 0):
                ConfigGPS[NPlot]["basemap"]["Edge Lower"] = Range_Y[0]
                ConfigGPS[NPlot]["basemap"]["Edge Upper"] = Range_Y[1]
            Edge_Left = ConfigGPS[NPlot]["basemap"]["Edge Left"]
            Edge_Right = ConfigGPS[NPlot]["basemap"]["Edge Right"]
            Edge_Lower = ConfigGPS[NPlot]["basemap"]["Edge Lower"]
            Edge_Upper = ConfigGPS[NPlot]["basemap"]["Edge Upper"]
        else:
            if (ConfigGPS[NPlot]["basemap"]["Edge Left"] == 0) and (ConfigGPS[NPlot]["basemap"]["Edge Right"] == 0):
                ConfigGPS[NPlot]["basemap"]["Edge Left"] = Edge_Left
                ConfigGPS[NPlot]["basemap"]["Edge Right"] = Edge_Right
            if (ConfigGPS[NPlot]["basemap"]["Edge Lower"] == 0) and (ConfigGPS[NPlot]["basemap"]["Edge Upper"] == 0):
                ConfigGPS[NPlot]["basemap"]["Edge Lower"] = Edge_Lower
                ConfigGPS[NPlot]["basemap"]["Edge Upper"] = Edge_Upper
        for nLayer in ConfigGPS[NPlot]:
            Layer = ConfigGPS[NPlot][nLayer]
            if Layer['Layer'] == "text":
                if Layer['Text'].find("GNSS Station") != -1:
                    Layer['Text'] = "GNSS Station:   " + GNSSDataset[0]
                if Layer['Text'].find("Lontitude") != -1:
                    Layer['Text'] = "Lontitude:   " + GNSSDataset[1][1]
                if Layer['Text'].find("Latitude") != -1:
                    Layer['Text'] = "Latitude:      " + GNSSDataset[1][0]
    ListConfig[it] = ConfigGPS
    pygmt._end()
    return ListConfig[it]

def get_gps(config, ListInputFile):
    NGNSS = len(ListInputFile)
    ListConfig = multiprocessing.Manager().list([{}]*NGNSS)
    ListInput = multiprocessing.Manager().list([""]*NGNSS)
    ListArgInput = []
    for it in range(0,NGNSS):
        ArgInput = (config, it, ListInputFile[it], ListConfig, ListInput)
        ListArgInput.append(ArgInput)
    parallelPool(get_GNSS_conf, ListArgInput)
    return [ListInput,ListConfig]

def plot(config):
    Code = ["import pygmt", "import os"]
    Type = config["IO"]["Type"]
    Input = config["IO"]["Input"]
    Output = config['IO']['Output']
    Batch = config["IO"]["Batch"]
    Plot_Width = config["IO"]["Plot Width"]
    Plot_Hight = config["IO"]["Plot Hight"]
    PlotsROWS = config["IO"]["Plots Per Row"]
    Margins = config["IO"]["Margins"]
    MarginsUnit = config["IO"]["Margins Unit"]
    AdditionPlots = config["IO"]["Additional Plot"]
    print(f"Plotting figure: {Output}")
    
    NPlot = len(Input)
    if (NPlot == 0):
        NPlot = 1
    pygmt._begin()
    fig = pygmt.Figure()
    Code.append("fig = pygmt.Figure()")
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
            plot_basemap(fig, Plot['basemap'],Code = Code)
            for iLayer in Plot:
                Layer = Plot[iLayer]
                if iLayer in config["IO"]["Layer"]:
                    Path_File = config["IO"]["Input"][it]
                    if not PurePath(Path_File).is_absolute():
                        Path_File = CurrentPath / Path_File
                    Layer["File Path"] = Path_File

                if Layer['Layer'] == "grdimage":
                    if not Layer['Plot']:
                        continue
                    plot_img(fig, Layer, Plot["basemap"]["Edge Left"], Plot["basemap"]["Edge Right"], Plot["basemap"]["Edge Lower"], Plot["basemap"]["Edge Upper"],Code = Code)
                elif Layer['Layer'] == "psxy":
                    if not Layer['Plot']:
                        continue
                    Dataset = 0
                    plot_xy(fig, Layer, Dataset, Code = Code)
                elif Layer['Layer'] == "ogr":
                    if not Layer['Plot']:
                        continue
                    plot_ogr(fig, Layer, Code = Code)
                elif Layer['Layer'] == "colorbar":
                    if not Layer['Plot']:
                        continue
                    plot_colorbar(fig, Layer, Plot[Layer['Link']],Code = Code)
                elif Layer['Layer'] == "text":
                    plot_text(fig, Layer,Code = Code)

            plot_Frame(fig, Plot['basemap'],Code = Code)

        ShiftX = str(ShiftX) + MarginsUnit
        ShiftY = str(ShiftY) + MarginsUnit
        fig.shift_origin(xshift=ShiftX,yshift=ShiftY)
        Code.append(f"fig.shift_origin(xshift=\"{ShiftX}\",yshift=\"{ShiftY}\")")
    # fig.show()
    InputName = ""
    if (Batch):
        InputName = Path(Input[0]).stem
        InputName = InputName.replace(Output,"")
        if len(InputName) != 0:
            Output = Output + "_" + InputName
    if not PurePath(Output).is_absolute():
        Output = CurrentPath / Path(Output)
    OutputFormat = "G"
    fig.psconvert(prefix=Output, fmt=OutputFormat, crop=True)
    Code.append(f"fig.psconvert(prefix=\"{Output}\", fmt=\"{OutputFormat}\", crop=True)")
    # Output = Output + "." + config['IO']['Format']
    # fig.savefig(Output, transparent=config['IO']['Transparent'])
    # for AdditionPlot in AdditionPlots:
    #     ConfigAddPlot = config_load(AdditionPlot)
    #     ConfigAddPlot['IO']['Output'] = ConfigAddPlot['IO']['Output'] + "_" + InputName
    #     plot(ConfigAddPlot)
    codedemo(Code)
    pygmt._end()

def parallelTask(ListTask):
    CPUs = multiprocessing.cpu_count()
    Active = [False]*len(ListTask)
    for it in range(0, len(ListTask)):
        while sum(Active) >= CPUs:
            for jt in range(0, len(ListTask)):
                if not ListTask[jt].is_alive():
                    Active[jt] = False
        ListTask[it].start()
        Active[it] = True
            
def parallelPool(function, ListArg, Threads=multiprocessing.cpu_count()):
    if len(ListArg) < Threads:
        Threads = len(ListArg)
    pool = multiprocessing.Pool(Threads)
    pool_outputs = pool.starmap(function, ListArg)
    pool.close()

def main():
    print(f"pyGMT plot Version: {Version} by Constantine VI.")
    config = {}
    setup_yaml()
    if len(sys.argv) < 2:
        usage()
    elif sys.argv[1] == "help":
        usage()
    else:
        if len(sys.argv) == 2:
            config = config_load(sys.argv[1])
        else:
            config = config_load(sys.argv[1], sys.argv[2])

    ListInput = []
    ListConfig = []
    Threads=multiprocessing.cpu_count()
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

    elif config["IO"]["Type"] == "gps":
        if len(sys.argv) >= 2:
            ListInputFile = sys.argv[2:len(sys.argv)]
        else:
            print("No input for GNSS time series plot, exiting.")
            exit(0)
        ListInputGNSS = get_gps(config, ListInputFile)
        ListConfig = ListInputGNSS[1]
        ListInput = ListInputGNSS[0]
    else:
        if len(sys.argv) > 2:
            for it in range(2,len(sys.argv)):
                ListInput.append([sys.argv[it]])
                ListConfig.append(copy.deepcopy(config))
        else:
            ListInput = config["IO"]["Input"]
            if ListInput == []:
                ListInput=[[0]]
            for Input in ListInput:
                ListConfig.append(copy.deepcopy(config))
    ListTask = []
    ListArgs = []
    for it in range(0,len(ListInput)):
        itConfig = ListConfig[it]
        itConfig["IO"]["Input"] = ListInput[it]
        ListArgs.append((itConfig,))
        # ListTask.append(multiprocessing.Process(target=plot, args=(itConfig,)))
    parallelPool(plot, ListArgs, Threads)
    # parallelTask(ListTask)
    # for Task in ListTask:
    #     Task.join()

# Main
if __name__=='__main__':
    start = time.time()
    main()
    print("pyGMT plot finish.")
    end = time.time()
    print(f"Used time: {format(end - start, '.2f')}s")