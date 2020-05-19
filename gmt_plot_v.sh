#!/bin/bash
# 將輸出之PS成果用GMT做成圖
# 這個程式主要用來輸出單圖，適用於PS速度場 / 地形、大氣誤差之輸出。
#
# 2017/09/20 CV 初版
# 2017/09/30 CV Feature:增加繪製底圖的選項
# 2018/01/11 CV Feature:增加繪製額外圖層的選項
# 2018/04/02 CV Feature:增加參數用以載入特定的設定檔
# 2018/06/13 CV Feature:預裁底圖，減少系統資源使用，避免過載
# 2018/06/20 CV Feature:增加轉檔功能
#               Feature:自動判定額外圖層類型，選擇適當的繪製模式
#               Feature:自動判定是否重裁底圖
#

# 搜尋檔案
if [ -f "ps_ll.txt" ];then
    Input_Data_lonlat=ps_ll.txt
else
    echo "Can't find ps_ll.txt."
fi

if [ -f "ps_mean_v.xy" ];then
    Input_Data=ps_mean_v.xy
else
    echo "Can't find ps_mean_v.xy."
fi

# Configure
if [ -z "${1}" ];then
config=gmt_plot_v.config
else
config=${1}
fi

if [ ! -f "${config}" ];then

# 計算底圖範圍
First_Lon=`cat ${Input_Data_lonlat} | awk '{printf("%f\n",$1)}' | gmt info -I0.1 -C | cut -f1`
Last_Lon=`cat ${Input_Data_lonlat} | awk '{printf("%f\n",$1)}' | gmt info -I0.1 -C | cut -f2`
Upper_Lat=`cat ${Input_Data_lonlat} | awk '{printf("%f\n",$2)}' | gmt info -I0.1 -C | cut -f2`
Lower_Lat=`cat ${Input_Data_lonlat} | awk '{printf("%f\n",$2)}' | gmt info -I0.1 -C | cut -f1`
Max_V=`cat ${Input_Data} | awk '{printf("%f\n",$3)}' | gmt info -I10 -C | cut -f2`
Min_V=`cat ${Input_Data} | awk '{printf("%f\n",$3)}' | gmt info -I10 -C | cut -f1`

echo "Please setup ${config} for input."
echo
echo "# Configure for gmt_plot_ps, please visit GMT website for more detail." >> ${config}

echo "# General setting" >> ${config}
echo "## FORMAT_GEO_MAP 地圖邊框座標格式" >> ${config}
echo "## MAP_FRAME_TYPE 地圖邊框形式，plain=細框，fancy=斑馬紋粗框" >> ${config}
echo "## FONT_ANNOT_PRIMARY 坐標軸字體設定" >> ${config}
echo "gmt_config=\"" >> ${config}
echo "FORMAT_GEO_MAP=ddd.xxF" >> ${config}
echo "MAP_FRAME_TYPE=fancy" >> ${config}
echo "MAP_FRAME_PEN=thicker" >> ${config}
echo "FONT=Times-Roman" >> ${config}
echo "FONT_LOGO=Times-Roman" >> ${config}
echo "FONT_TITLE=24p,Times-Roman" >> ${config}
echo "FONT_ANNOT_PRIMARY=12p,Times-Roman" >> ${config}
echo "\"" >> ${config}
echo "## 輸入選項" >> ${config}
echo "Input_Data=ps_mean_v.xy" >> ${config}
echo "## 輸出選項" >> ${config}
echo "Output_File=GMT_PS_v_plot" >> ${config}
echo "## 輸出圖檔格式，支援JPG、PNG、PDF、TIFF、BMP、EPS、PPM、SVG" >> ${config}
echo "Output_Figure_Format=PNG" >> ${config}
echo "## 自動裁切空白的部分" >> ${config}
echo "Output_Figure_Adjust=true" >> ${config}
echo "## PNG圖檔背景是否為透明" >> ${config}
echo "Output_Figure_Transparent=true" >> ${config}
echo "" >> ${config}

echo "# Basemap setting" >> ${config}
echo "## 設定底圖範圍，注意！底圖範圍不可以超出底圖檔案範圍" >> ${config}
echo "First_Lon=${First_Lon}" >> ${config}
echo "Last_Lon=${Last_Lon}" >> ${config}
echo "Upper_Lat=${Upper_Lat}" >> ${config}
echo "Lower_Lat=${Lower_Lat}" >> ${config}
echo "## 設定投影方式，M=橫麥卡托投影" >> ${config}
echo "Map_Projection=M" >> ${config}
echo "## 設定底圖大小" >> ${config}
echo "Map_Width=15" >> ${config}
echo "## 設定底圖大小單位，c=公分，i=英吋，p=point" >> ${config}
echo "Map_Width_unit=c" >> ${config}
echo "## 設定坐標軸刻度間隔，格式=a[顯示數值之刻度]b[不顯示數值之刻度]" >> ${config}
echo "basemap_Bx=a0.5" >> ${config}
echo "basemap_By=a0.5" >> ${config}
echo "## 是否繪製底圖" >> ${config}
echo "Plot_Basemap=true" >> ${config}
echo "## 輸入底圖的絕對路徑" >> ${config}
echo "Basemap=" >> ${config}
echo "## 底圖類型，DEM=數值地形模型，IFG=差分干涉圖，IMG=多光譜影像" >> ${config}
echo "Basemap_Type=DEM" >> ${config}
echo "## 輸出底圖名稱" >> ${config}
echo "Basemap_Output=basemap_crop.tif" >> ${config}
echo "## 是否重新計算DEM陰影" >> ${config}
echo "Make_Shade=true" >> ${config}
echo "## 設定DEM/IFG色帶樣式，gray=灰階，jet=彩虹" >> ${config}
echo "makecpt_C_Basemap=gray" >> ${config}
echo "## 設定DEM/IFG色帶，格式=[最小值]/[最大值]/[變色間隔]" >> ${config}
echo "makecpt_T_Basemap=-1000/1000/1" >> ${config}
echo "## 底圖位置偏移量" >> ${config}
echo "Offset_X=" >> ${config}
echo "Offset_Y=4" >> ${config}

echo "# scale setting" >> ${config}
echo "## 圖例文字說明" >> ${config}
echo "scale_Label=\"LOS Velocity (mm/yr)\"" >> ${config}
echo "## 設定圖例坐標軸刻度間隔" >> ${config}
echo "scale_B=a2f1" >> ${config}
echo "" >> ${config}

echo "# makecpt setting" >> ${config}
echo "## 設定Colorbar大小，格式=[最小值]/[最大值]/[變色間隔]" >> ${config}
echo "makecpt_T_PS=${Min_V}/${Max_V}/1" >> ${config}
echo "" >> ${config}

echo "# psxy setting" >> ${config}
echo "## 設定資料點樣式與大小，格式=[樣式代號][大小]，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
echo "psxy_Size=c0.02" >> ${config}
echo "" >> ${config}

echo "## 額外圖層" >> ${config}
echo "Addition_Layers=\"" >> ${config}
echo "\"" >> ${config}
echo "## 設定點樣式與大小，格式=[樣式代號][大小]，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
echo "Layer_Point_Size=" >> ${config}
echo "Layer_Point_Color=" >> ${config}
echo "## 設定線寬度與顏色，格式=[線寬],[顏色]" >> ${config}
echo "Layer_Line_Size=" >> ${config}
echo "## 設定多邊形樣式" >> ${config}
echo "## 設定多邊形邊線寬與顏色，格式=[線寬],[顏色]" >> ${config}
echo "Layer_Polygon_Line_Size=" >> ${config}
echo "## 設定多邊形填充顏色，格式=[顏色]" >> ${config}
echo "Layer_Polygon_Color=" >> ${config}
echo "" >> ${config}

echo "# title setting" >> ${config}
echo "## 標題高度位置偏移量(相對於底圖底部)" >> ${config}
echo "Title_Offset_Y=11" >> ${config}
echo "Title_FONT_Size=20" >> ${config}
echo "Sub_Title_FONT_Size=16" >> ${config}
echo "Title=\"\"" >> ${config}
echo "Sub_Title=\"\"" >> ${config}

exit 1
fi

# 當前目錄
pwd=`pwd`

# 讀取設定檔
source ${pwd}/${config}
Output_File_Name=${Output_File}.ps

# 讀取參數
psbasemap_J=${Map_Projection}${Map_Width}${Map_Width_unit}
if [ "${Offset_X}" != "" ];then
    X=-X${Offset_X}
fi
if [ "${Offset_Y}" != "" ];then
    Y=-Y${Offset_Y}
fi

# GMT廣域設定
gmt gmtset ${gmt_config}

# 底圖設定
gmt psbasemap -J${psbasemap_J} -R${First_Lon}/${Last_Lon}/${Lower_Lat}/${Upper_Lat} -BWSen+t"${Title}" -Bx${basemap_Bx} -By${basemap_By} ${X} ${Y} -K -P -V > ${Output_File_Name}

# 繪製底圖
if [ -f "${Basemap_Output}" ];then
    basemap_crop_xmin=`grdinfo ${Basemap_Output} | grep 'x_min' | awk '{print $3}'`
    basemap_crop_xmax=`grdinfo ${Basemap_Output} | grep 'x_min' | awk '{print $5}'`
    basemap_crop_ymin=`grdinfo ${Basemap_Output} | grep 'y_min' | awk '{print $3}'`
    basemap_crop_ymax=`grdinfo ${Basemap_Output} | grep 'y_min' | awk '{print $5}'`
    First_Lon_Sub=`gmt math -Q ${First_Lon} ${basemap_crop_xmin} SUB ABS 0.001 GT =`
    Last_Lon_Sub=`gmt math -Q ${Last_Lon} ${basemap_crop_xmax} SUB ABS 0.001 GT =`
    Lower_Lat_Sub=`gmt math -Q ${Lower_Lat} ${basemap_crop_ymin} SUB ABS 0.001 GT =`
    Upper_Lat_Sub=`gmt math -Q ${Upper_Lat} ${basemap_crop_ymax} SUB ABS 0.001 GT =`
    if [ "${First_Lon_Sub}" -eq 1 ] || [ "${Last_Lon_Sub}" -eq 1 ] ||[ "${Lower_Lat_Sub}" -eq 1 ] ||[ "${Upper_Lat_Sub}" -eq 1 ];then
        gdal_translate -projwin ${First_Lon} ${Upper_Lat} ${Last_Lon} ${Lower_Lat} -of GTiff ${Basemap} ${Basemap_Output}
    fi
else
    gdal_translate -projwin ${First_Lon} ${Upper_Lat} ${Last_Lon} ${Lower_Lat} -of GTiff ${Basemap} ${Basemap_Output}
fi

if [ "${Plot_Basemap}" == "true" ];then
    if [ "${Basemap_Type}" == "DEM" ];then
        # 計算DEM陰影
        if [ "${Make_Shade}" == "true" ] || [ ! -f "shade.grd" ];then
			echo ${Make_Shade}
            gmt grdgradient ${Basemap_Output} -Gshade.grd -A0 -Ne0.6 -V
            sed -i 's/Make_Shade=true/Make_Shade=false/g' ${config}
        fi
        # 將DEM底圖加上灰階
        gmt makecpt -C${makecpt_C_Basemap} -T${makecpt_T_Basemap} -Z > basemap_cpt.cpt
        gmt grdimage ${Basemap_Output} -Cbasemap_cpt.cpt -Ishade.grd -J -R -K -O -P -V >> ${Output_File_Name}
    elif [ "${Basemap_Type}" == "IFG" ];then
        gmt makecpt -C${makecpt_C_Basemap} -T${makecpt_T_Basemap} -Z > basemap_cpt.cpt
        gmt grdimage ${Basemap_Output} -Cbasemap_cpt.cpt -J -R -K -O -P -V >> ${Output_File_Name}
    elif [ "${Basemap_Type}" == "IMG" ];then
        gmt grdimage ${Basemap_Output}+b0 ${Basemap_Output}+b1 ${Basemap_Output}+b2 -J -R -K -O -P -V >> ${Output_File_Name}
    fi
fi

# Plot PS LOS velocity points
# 將PS繪製至底圖上並加上色彩
if [ -f "${Input_Data}" ];then
    gmt makecpt -Cjet -T${makecpt_T_PS} -Z > ps.cpt
    awk '{print $1, $2, $3}' ${Input_Data} | gmt psxy -J -R -S${psxy_Size} -Cps.cpt -K -O -V >> ${Output_File_Name}
else
    echo "Can't find ${Input_Data}, skip psxy plotting."
fi

# 將額外圖層繪製至底圖上
if [ "${Addition_Layers}" ];then
    for Addition_Layer in ${Addition_Layers}
    do
        LayerFileName=`echo ${Addition_Layer} | sed 's/.*\///g' | sed 's/\.*//g'`
        LayerIdentify=`echo ${Addition_Layer} | sed 's/.*\.//g'`
        if [ "${LayerIdentify}" == "shp" ];then
            ogr2ogr -f gmt ${LayerFileName}.gmt ${Addition_Layer}
            Addition_Layer=${LayerFileName}.gmt
            ShapeTypeIdentify=`nl ${Addition_Layer} | sed -n '1p'`
        elif [ "${LayerIdentify}" == "gmt" ];then
            ShapeTypeIdentify=`nl ${Addition_Layer} | sed -n '1p'`
        elif [ "${LayerIdentify}" == "txt" ];then
            ShapeTypeIdentify=POINT
        else
            echo "Not support ${LayerIdentify} format, skip layer plotting."
        fi

        if [ "`echo ${ShapeTypeIdentify} | grep 'POINT'`" ];then
            ShapeType=point
            gmt psxy ${Addition_Layer} -J -R -G${Layer_Point_Color} -S${Layer_Point_Size} -K -O -V >> ${Output_File_Name}
        elif [ "`echo ${ShapeTypeIdentify} | grep 'LINE'`" ];then
            ShapeType=line
            gmt psxy ${Addition_Layer} -J -R -W${Layer_Line_Size} -K -O -V >> ${Output_File_Name}
        elif [ "`echo ${ShapeTypeIdentify} | grep 'POLYGON'`" ];then
            ShapeType=polygon
            gmt psxy ${Addition_Layer} -J -R -G${Layer_Polygon_Color} -W${Layer_Polygon_Line_Size} -K -O -V >> ${Output_File_Name}
        fi
    done
fi
# Profile line
#psxy profile_line.txt -JM -R -W6 -V -m -K -O>>${Output_File_Name}

# coastline
gmt pscoast -J -R -B -Df -S140/206/250 -W2/0 -V -K -O >> ${Output_File_Name}

# Colorbar
gmt psscale -Cps.cpt -J -R -DjBC+w10c/0.5c+jTC+h+o0/1c -B${scale_B}+l"${scale_Label}" -K -O -P -V >> ${Output_File_Name}

# 寫入文字
#gmt pstext -R0/1/0/1 -JX1c -F+f${Title_FONT_Size}p,Helvetica-Bold+jMC -Xc -Y$((${Title_Offset_Y}+2))c -K -O -P -N -V <<!>> ${Output_File_Name}
#0 0 ${Title}
#!
#gmt pstext -JX -R -F+f${Sub_Title_FONT_Size}p,Helvetica-Bold+jMC -Y-1c -O -P -N -V <<!>> ${Output_File_Name}
#0 0 ${Sub_Title}
#!
gmt psxy -R -J -T -O >> ${Output_File_Name}
# 轉檔
if [ "${Output_Figure_Format}" == "PNG" ];then
    if [ "${Output_Figure_Transparent}" == "true" ];then
        psconvert_T=G
    else
        psconvert_T=g
    fi
elif [ "${Output_Figure_Format}" == "JPG" ];then
    psconvert_T=j
elif [ "${Output_Figure_Format}" == "JPG" ];then
    psconvert_T=j
elif [ "${Output_Figure_Format}" == "BMP" ];then
    psconvert_T=b
elif [ "${Output_Figure_Format}" == "TIFF" ];then
    psconvert_T=t
elif [ "${Output_Figure_Format}" == "PPM" ];then
    psconvert_T=m
elif [ "${Output_Figure_Format}" == "PDF" ];then
    psconvert_T=f
elif [ "${Output_Figure_Format}" == "SVG" ];then
    psconvert_T=s
elif [ "${Output_Figure_Format}" == "EPS" ];then
    psconvert_T=e
fi
psconvert_T=-T${psconvert_T}

if [ "${Output_Figure_Adjust}" == "true" ];then
    psconvert_A=-A
fi
psconvert ${psconvert_T} ${psconvert_A} -P ${Output_File_Name}
