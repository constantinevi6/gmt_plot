#!/bin/bash
# InSAR GMT製圖程序
#
#整合與模組化各項製圖程序
# 2018/07/24 CV 初版
#
function help(){
    echo "This is a help information."
}

function help_config(){
    echo "Please setup ${config} for input."
    echo
}

function define_io(){
    Input_Data=ps_mean_v.xy
    Input_Date=date.txt
    Input_Bperp=bperp.txt
    Input_SBAS=small_baselines.list
    Input_LonLat=ps_ll.txt
}

function define_io_gps(){
    Input_Data=*.COR
    Input_Date=
    Input_Bperp=
    Input_SBAS=
    Input_LonLat=
}

function define_configure(){
    if [ -z "${Input_config}" ];then
        config=gmt_plot_${mode}.config
    else
        config=${Input_config}
    fi
}

function define_ts_list(){
    if [ -e "${TS_list}" ];then
        TS_list=${TS_list}
    else
        unset TS_list
    fi
}

function config_gereral(){
    echo "# Configure for gmt_plot, please visit GMT website for more detail." > ${config}
    echo "# General setting" >> ${config}
    echo "## FORMAT_GEO_MAP 地圖邊框座標格式" >> ${config}
    echo "## MAP_FRAME_TYPE 地圖邊框形式，plain=細框，fancy=斑馬紋粗框" >> ${config}
    echo "## FONT_ANNOT_PRIMARY 坐標軸字體設定" >> ${config}
    echo "gmt_config=\"" >> ${config}
    if [ "${mode}" == "velocity" ];then
        echo "FORMAT_GEO_MAP=ddd.xxF" >> ${config}
        echo "MAP_FRAME_TYPE=fancy" >> ${config}
        echo "MAP_FRAME_PEN=thicker" >> ${config}
        echo "MAP_ANNOT_OFFSET=5p" >> ${config}
        echo "FONT=Times-Roman" >> ${config}
        echo "FONT_LOGO=Times-Roman" >> ${config}
        echo "FONT_TITLE=24p,Times-Roman" >> ${config}
        echo "FONT_ANNOT_PRIMARY=12p,Times-Roman" >> ${config}
    elif [ "${mode}" == "deformation" ];then
        echo "FORMAT_GEO_MAP=ddd.xxF" >> ${config}
        echo "MAP_FRAME_TYPE=plain" >> ${config}
        echo "MAP_FRAME_PEN=thicker" >> ${config}
        echo "FONT=Times-Roman" >> ${config}
        echo "FONT_LOGO=Times-Roman" >> ${config}
        echo "FONT_ANNOT_PRIMARY=6p,Times-Roman" >> ${config}
    elif [ "${mode}" == "timeseries" ];then
        echo "FORMAT_DATE_IN=yyyymmdd" >> ${config}
        echo "FORMAT_DATE_OUT=yyyy-mm-dd" >> ${config}
        echo "FORMAT_DATE_MAP=o" >> ${config}
        echo "FORMAT_TIME_PRIMARY_MAP=abbreviated" >> ${config}
        echo "FONT=Times-Roman" >> ${config}
        echo "FONT_LOGO=Times-Roman" >> ${config}
        echo "FONT_TITLE=24p,Times-Roman" >> ${config}
        echo "FONT_ANNOT_PRIMARY=20p,Times-Roman" >> ${config}
        echo "FONT_ANNOT_SECONDARY=18p,Times-Roman" >> ${config}
        echo "FONT_LABEL=18p,Times-Roman" >> ${config}
        echo "MAP_ANNOT_OFFSET_PRIMARY=16p" >> ${config}
        echo "MAP_ANNOT_OFFSET_SECONDARY=20p" >> ${config}
    elif [ "${mode}" == "baseline" ];then
        echo "FORMAT_DATE_IN=yyyymmdd" >> ${config}
        echo "FORMAT_DATE_OUT=yyyy-mm-dd" >> ${config}
        echo "FORMAT_DATE_MAP=o" >> ${config}
        echo "FORMAT_TIME_PRIMARY_MAP=abbreviated" >> ${config}
        echo "FONT=Times-Roman" >> ${config}
        echo "FONT_LOGO=Times-Roman" >> ${config}
        echo "FONT_TITLE=24p,Times-Roman" >> ${config}
        echo "FONT_ANNOT_PRIMARY=20p,Times-Roman" >> ${config}
        echo "FONT_ANNOT_SECONDARY=18p,Times-Roman" >> ${config}
        echo "FONT_LABEL=18p,Times-Roman" >> ${config}
    elif [ "${mode}" == "gps" ];then
        echo "FORMAT_DATE_IN=yyyymmdd" >> ${config}
        echo "FORMAT_DATE_OUT=yyyy-mm-dd" >> ${config}
        echo "FORMAT_DATE_MAP=o" >> ${config}
        echo "FORMAT_TIME_PRIMARY_MAP=abbreviated" >> ${config}
        echo "FONT=Times-Roman" >> ${config}
        echo "FONT_LOGO=Times-Roman" >> ${config}
        echo "FONT_TITLE=24p,Times-Roman" >> ${config}
        echo "FONT_ANNOT_PRIMARY=20p,Times-Roman" >> ${config}
        echo "FONT_ANNOT_SECONDARY=18p,Times-Roman" >> ${config}
        echo "FONT_LABEL=18p,Times-Roman" >> ${config}
        echo "MAP_ANNOT_OFFSET_PRIMARY=16p" >> ${config}
        echo "MAP_ANNOT_OFFSET_SECONDARY=20p" >> ${config}
    fi
    echo "\"" >> ${config}
    echo "" >> ${config}
}

function config_io(){
    echo "# IO setting" >> ${config}
    echo "## 輸入選項，Input_Data格式:(d-Mode, ts-Mode)[PS輸出檔案].*.xy (v-Mode)[PS輸出檔案].xy" >> ${config}
    echo "Input_Data=${Input_Data}" >> ${config}
    echo "Input_Date=${Input_Date}" >> ${config}
    echo "Input_Bperp=${Input_Bperp}" >> ${config}
    echo "Input_SBAS=${Input_SBAS}" >> ${config}
    echo "Input_LonLat=${Input_LonLat}" >> ${config}
    echo "## 輸出選項" >> ${config}
    echo "Output_File_Name=GMT_${mode}" >> ${config}
    echo "## 輸出圖檔格式，支援JPG、PNG、PDF、TIFF、BMP、EPS、PPM、SVG" >> ${config}
    echo "Output_Figure_Format=PNG" >> ${config}
    echo "## 自動裁切空白的部分" >> ${config}
    echo "Output_Figure_Adjust=true" >> ${config}
    echo "## PNG圖檔背景是否為透明" >> ${config}
    echo "Output_Figure_Transparent=true" >> ${config}
    echo "" >> ${config}
}

function config_psbasemap(){
    echo "# GMT psbasemap setting" >> ${config}
    echo "## 設定底圖範圍，注意！底圖範圍不可以超出底圖檔案範圍" >> ${config}
    echo "Edge_Left=${Edge_Left}" >> ${config}
    echo "Edge_Right=${Edge_Right}" >> ${config}
    echo "Edge_Upper=${Edge_Upper}" >> ${config}
    echo "Edge_Lower=${Edge_Lower}" >> ${config}
    echo "## 設定投影方式，M=橫麥卡托投影，X=線性、指數直角坐標系" >> ${config}
    echo "Map_Projection=${Map_Projection}" >> ${config}
    echo "## 設定底圖大小" >> ${config}
    echo "Map_Width=${Map_Width}" >> ${config}
    echo "Map_High=${Map_High}" >> ${config}
    echo "## 設定底圖大小單位，c=公分，i=英吋，p=point" >> ${config}
    echo "Map_Width_unit=i" >> ${config}
    echo "## 設定坐標軸刻度間隔，格式=a[顯示數值之刻度]b[不顯示數值之刻度]" >> ${config}
    echo "Map_Bax=${Map_Bax}" >> ${config}
    echo "Map_Bbx=${Map_Bbx}" >> ${config}
    echo "Map_Bay=${Map_Bay}" >> ${config}
    echo "Map_Bby=${Map_Bby}" >> ${config}
    echo "## 底圖位置偏移量" >> ${config}
    echo "Map_Offset_X=${Map_Offset_X}" >> ${config}
    echo "Map_Offset_Y=${Map_Offset_Y}" >> ${config}
    echo "" >> ${config}
}

function config_basemap_image(){
    echo "# Basemap setting" >> ${config}
    echo "## 是否繪製底圖" >> ${config}
    echo "Plot_Basemap=false" >> ${config}
    echo "## 輸入底圖的絕對路徑" >> ${config}
    echo "Basemap_Path=" >> ${config}
    echo "## 底圖類型，DEM=數值地形模型，IFG=差分干涉圖，IMG=多光譜影像" >> ${config}
    echo "Basemap_Type=DEM" >> ${config}
    echo "## 輸出底圖名稱" >> ${config}
    echo "Basemap_Output=Basemap_crop" >> ${config}
    echo "## 設定DEM/IFG色帶樣式，gray=灰階，jet=彩虹" >> ${config}
    echo "Basemap_makecpt_color=" >> ${config}
    echo "## 設定DEM/IFG色帶，格式=[最小值]/[最大值]/[變色間隔]" >> ${config}
    echo "Basemap_makecpt=" >> ${config}
}

function config_psxy_PS(){
    echo "# psxy setting" >> ${config}
    echo "## 設定資料點樣式與大小，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
    echo "psxy_Size=0.02" >> ${config}
    echo "psxy_Type=c" >> ${config}
    echo "psxy_G=" >> ${config}
    echo "## 設定Colorbar，格式=[最小值]/[最大值]/[變色間隔]" >> ${config}
    echo "psxy_makecpt=-${cpt}/${cpt}/0.01" >> ${config}
    echo "psxy_makecpt_color=jet" >> ${config}
    echo "" >> ${config}
}

function config_psxy_baseline(){
    echo "# psxy setting" >> ${config}
    echo "## 設定資料點樣式與大小，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
    echo "psxy_Size=0.2" >> ${config}
    echo "psxy_Type=c" >> ${config}
    echo "psxy_G=black" >> ${config}
    echo "## 設定主影像資料點樣式與大小" >> ${config}
    echo "M_psxy_Size=0.4" >> ${config}
    echo "M_psxy_Type=c" >> ${config}
    echo "M_psxy_G=red" >> ${config}
    echo "## 設定連線樣式" >> ${config}
    echo "psxy_W=2p,gray" >> ${config}
    echo "" >> ${config}
}

function config_psxy_timeseries(){
    echo "# psxy setting" >> ${config}
    echo "## 設定資料點樣式與大小，格式=[樣式代號][大小]，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
    echo "## 是否繪製各PS點變形量" >> ${config}
    echo "Plot_single_PS=false" >> ${config}
    echo "psxy_Size=c0.1" >> ${config}
    echo "## 是否繪製平均變形量" >> ${config}
    echo "Plot_Mean_PS=ture" >> ${config}
    echo "psxy_Size_Mean=c0.2" >> ${config}
    echo "psxy_G=black" >> ${config}
    echo "## 設定連線樣式" >> ${config}
    echo "psxy_W=1p" >> ${config}

    echo "## 設定PS中心座標與範圍，範圍單位:m" >> ${config}
    echo "PS_Center_Lon=" >> ${config}
    echo "PS_Center_Lat=" >> ${config}
    echo "PS_Radius=10" >> ${config}
}

function config_scale(){
    echo "# scale setting" >> ${config}
    echo "## 圖例文字說明" >> ${config}
    echo "scale_Label=\"${scale_Label}\"" >> ${config}
    echo "## 設定圖例坐標軸刻度間隔" >> ${config}
    echo "scale_Ba=50" >> ${config}
    echo "scale_Bf=10" >> ${config}
    echo "" >> ${config}
}

function config_addition_layer(){
    echo "# 額外圖層" >> ${config}
    echo "## 額外圖層檔案,大小/樣式,顏色(,填充顏色)" >> ${config}
    echo "Addition_Layers=\"" >> ${config}
    echo "\"" >> ${config}
    echo "## 設定點預設樣式與大小，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
    echo "Layer_Point_Size=" >> ${config}
    echo "Layer_Point_Color=" >> ${config}
    echo "## 設定線預設寬度[p]與顏色" >> ${config}
    echo "Layer_Line_Size=" >> ${config}
    echo "Layer_Line_Color=" >> ${config}
    echo "## 設定多邊形預設樣式" >> ${config}
    echo "## 設定多邊形邊線寬與顏色" >> ${config}
    echo "Layer_Polygon_Line_Size=" >> ${config}
    echo "Layer_Polygon_Line_Color=" >> ${config}
    echo "## 圖層位置，在PS之前=front，在PS之後=back" >> ${config}
    echo "Addition_Layers_Position=front" >> ${config}
    echo "" >> ${config}
}

function config_title(){
    argvs=$@
    for argv in ${argvs}
    do
        Title="${Title} ${argv}"
    done
    echo "# title setting" >> ${config}
    echo "Title=\"${Title}\" " >> ${config}
}

function config_default_v(){
    Map_Projection=M
    Map_Width=6
    Map_Offset_Y=4
    Map_Bax=1
    Map_Bbx=0.2
    Map_Bay=1
    Map_Bby=0.2
    scale_Label="LOS Velocity (mm/yr)"
}

function config_default_ts(){
    Map_Projection=X
    Map_Width=9
    Map_High=6
    Map_Bax=1
    Map_Bbx=3
    Map_Bay=50
    Map_Bby=10
}

function config_default_gps(){
    Map_Projection=X
    Map_Width=9
    Map_High=4
    Map_Bax=1
    Map_Bbx=3
    Map_Bay=50
    Map_Bby=10
}

function config_ddd(){
    exit
}

function setting_config(){
    source ${pwd}/${config}
    gmt gmtset ${gmt_config}
}

function setting_output(){
    if [ $# -eq 0 ];then
        Output_File=${Output_File_Name}.ps
    else
        Output_File=${Output_File_Name}
        argvs=$@
        for argv in ${argvs}
        do
            Output_File=${Output_File}_${argv}
        done
        Output_File=${Output_File}.ps
    fi
}

function setting_argument(){
    psbasemap_J=${Map_Projection}${Map_Width}${Map_Width_unit}
    if [ ! -z "${Map_High}" ];then
        psbasemap_J=${psbasemap_J}/${Map_High}${Map_Width_unit}
    fi
    if [ "${Map_Projection}" == "X" ];then
        psbasemap_Bx=a${Map_Bax}f${Map_Bbx}
        psbasemap_By=a${Map_Bay}f${Map_Bby}
    else
        psbasemap_Bx=a${Map_Bax}b${Map_Bbx}
        psbasemap_By=a${Map_Bay}b${Map_Bby}
    fi
    psxy_Size=${psxy_Type}${psxy_Size}
    M_psxy_Size=${M_psxy_Type}${M_psxy_Size}
    scale_B=a${scale_Ba}f${scale_Bf}
    if [ "${psxy_W}" == "-" ];then
        psxy_W=-W${psxy_W}
    elif [ ! -z "${psxy_W}" ];then
        errorbar=-Ey/${psxy_W}
        psxy_W=-W${psxy_W}
    fi
}

function setting_XYOffset(){
    if [ $# -ne 0 ];then
    X=-X${1}
    Y=-Y${2}
    fi
}

function define_edge(){
    Edge_Left=`cat ${Input_X} | awk '{printf("%d\n",$1)}' | gmt info -I1 -C | cut -f1`
    Edge_Right=`cat ${Input_X} | awk '{printf("%d\n",$1)}' | gmt info -I1 -C | cut -f2`
    Edge_Lower=`cat ${Input_Y} | awk '{printf("%d\n",$1)}' | gmt info -I1 -C | cut -f1`
    Edge_Upper=`cat ${Input_Y} | awk '{printf("%d\n",$1)}' | gmt info -I1 -C | cut -f2`
}

function define_edge_time(){
    gmt gmtset FORMAT_DATE_IN yyyymmdd FORMAT_DATE_OUT yyyy-mm-dd
    Edge_Left=`cat ${Input_X} | awk '{printf("%d\n",$1)}' | gmt info -fT -I1 -C | cut -f1`
    Edge_Right=`cat ${Input_X} | awk '{printf("%d\n",$1)}' | gmt info -fT -I1 -C | cut -f2`
    Edge_Lower=`cat ${Input_Y} | awk '{printf("%d\n",$1)}' | gmt info -I50 -C | cut -f1`
    Edge_Upper=`cat ${Input_Y} | awk '{printf("%d\n",$1)}' | gmt info -I50 -C | cut -f2`
    Edge_Y=`gmt math -Q ${Edge_Lower} ${Edge_Upper} MAX =`
    Edge_Lower=-${Edge_Y}
    Edge_Upper=${Edge_Y}
}

function define_edge_geo(){
    Edge_Left=`cat ${Input_LonLat} | awk '{printf("%f\n",$1)}' | gmt info -I0.1 -C | cut -f1`
    Edge_Right=`cat ${Input_LonLat} | awk '{printf("%f\n",$1)}' | gmt info -I0.1 -C | cut -f2`
    Edge_Upper=`cat ${Input_LonLat} | awk '{printf("%f\n",$2)}' | gmt info -I0.1 -C | cut -f2`
    Edge_Lower=`cat ${Input_LonLat} | awk '{printf("%f\n",$2)}' | gmt info -I0.1 -C | cut -f1`
}

function define_edge_cpt(){
    max_cpt=`cat ${Input_Data} | awk '{printf("%f\n",$3)}' | gmt info -I10 -C | cut -f2`
    min_cpt=`cat ${Input_Data} | awk '{printf("%f\n",$3)}' | gmt info -I10 -C | cut -f1`
    max_cpt_abs=`gmt math -Q ${max_cpt} ABS =`
    min_cpt_abs=`gmt math -Q ${min_cpt} ABS =`
    cpt=`gmt math -Q ${max_cpt_abs} ${min_cpt_abs} MAX =`
}

function crop_image(){
    Basemap_Output=${Basemap_Output}_${Basemap_Type}.tif
    if [ -f "${Basemap_Output}" ];then
        basemap_crop_xmin=`grdinfo ${Basemap_Output} | grep 'x_min' | awk '{print $3}'`
        basemap_crop_xmax=`grdinfo ${Basemap_Output} | grep 'x_min' | awk '{print $5}'`
        basemap_crop_ymin=`grdinfo ${Basemap_Output} | grep 'y_min' | awk '{print $3}'`
        basemap_crop_ymax=`grdinfo ${Basemap_Output} | grep 'y_min' | awk '{print $5}'`
        First_Lon_Sub=`gmt math -Q ${Edge_Left} ${basemap_crop_xmin} SUB ABS 0.0001 GT =`
        Last_Lon_Sub=`gmt math -Q ${Edge_Right} ${basemap_crop_xmax} SUB ABS 0.0001 GT =`
        Lower_Lat_Sub=`gmt math -Q ${Edge_Lower} ${basemap_crop_ymin} SUB ABS 0.0001 GT =`
        Upper_Lat_Sub=`gmt math -Q ${Edge_Upper} ${basemap_crop_ymax} SUB ABS 0.0001 GT =`
        if [ "${First_Lon_Sub}" -eq 1 ] || [ "${Last_Lon_Sub}" -eq 1 ] ||[ "${Lower_Lat_Sub}" -eq 1 ] ||[ "${Upper_Lat_Sub}" -eq 1 ];then
            gdal_translate -projwin ${Edge_Left} ${Edge_Upper} ${Edge_Right} ${Edge_Lower} -of GTiff ${Basemap_Path} ${Basemap_Output}
        fi
    else
        gdal_translate -projwin ${Edge_Left} ${Edge_Upper} ${Edge_Right} ${Edge_Lower} -of GTiff ${Basemap_Path} ${Basemap_Output}
    fi
    # 計算DEM陰影
    if [ "${Basemap_Type}" == "DEM" ];then
        gmt grdgradient ${Basemap_Output} -Gshade.grd -A0 -Ne0.6 -V
    fi
}

function plot_basemap_image(){
    if [ "${Basemap_Type}" == "DEM" ];then
        # 將DEM底圖加上灰階
        if [ -z "${Basemap_makecpt_color}" ];then
            Basemap_makecpt_color=gray
        fi
        if [ -z "${Basemap_makecpt}" ];then
            Basemap_makecpt=-1000/1000/1
        fi
        gmt makecpt -C${Basemap_makecpt_color} -T${Basemap_makecpt} -Z > image_cpt.cpt
        gmt grdimage ${Basemap_Output} -Cimage_cpt.cpt -Ishade.grd -J -R -K -O -P -V >> ${Output_File}
    elif [ "${Basemap_Type}" == "IFG" ];then
        if [ -z "${Basemap_makecpt_color}" ];then
            Basemap_makecpt_color=jet
        fi
        if [ -z "${Basemap_makecpt}" ];then
            Basemap_makecpt=-3.14/3.14/0.01
        fi
        gmt makecpt -C${Basemap_makecpt_color} -T${Basemap_makecpt} -Z > image_cpt.cpt
        gmt grdimage ${Basemap_Output} -Cimage_cpt.cpt -J -R -K -O -P -V >> ${Output_File}
    elif [ "${Basemap_Type}" == "IMG" ];then
        gmt grdimage ${Basemap_Output}+b0 ${Basemap_Output}+b1 ${Basemap_Output}+b2 -J -R -E300 -K -O -P -V >> ${Output_File}
    fi
}

function plot_ps(){
    gmt makecpt -C${psxy_makecpt_color} -T${psxy_makecpt} -Z > ps.cpt
    gmt psxy ${Input_Data} -J -R -S${psxy_Size} -Cps.cpt -K -O -V >> ${Output_File}
}

function plot_coastline(){
    gmt pscoast -J -R -B -Df -S140/206/250 -W2/0 -V -K -O >> ${Output_File}
}

function plot_legend(){
    gmt psscale -C${1} -J -R -DjBC+w10c/0.5c+jTC+h+o0/1c -B${scale_B}+l"${scale_Label}" -K -O -P -V >> ${Output_File}
}

function plot_add_layer(){
    for Addition_Layer in ${Addition_Layers}
    do
        LayerFile=`echo ${Addition_Layer} | awk 'BEGIN {FS = ","} {print $1}'`
        LayerFileName=`echo ${LayerFile} | sed 's/.*\///g' | sed 's/\..*//g'`
        LayerIdentify=`echo ${LayerFile} | sed 's/.*\.//g'`
        echo Processing ${LayerFileName}
        if [ "${LayerIdentify}" == "shp" ];then
            ogr2ogr -f gmt ${LayerFileName}.gmt ${LayerFile}
            LayerFile=${LayerFileName}.gmt
            ShapeTypeIdentify=`nl ${LayerFile} | sed -n '1p'`
        elif [ "${LayerIdentify}" == "gmt" ];then
            ShapeTypeIdentify=`nl ${LayerFile} | sed -n '1p'`
        elif [ "${LayerIdentify}" == "txt" ];then
            ShapeTypeIdentify=POINT
        else
            echo "Not support ${LayerIdentify} format, skip layer plotting."
        fi

        Layer_Size=`echo ${Addition_Layer} | awk 'BEGIN {FS = ","} {print $2}'`
        Layer_Color=`echo ${Addition_Layer} | awk 'BEGIN {FS = ","} {print $3}'`
        Fill_Color=`echo ${Addition_Layer} | awk 'BEGIN {FS = ","} {print $4}'`
        
        if [ "`echo ${ShapeTypeIdentify} | grep 'POINT'`" ];then
            if [ -z "${Layer_Size}" ];then
                Layer_Size=${Layer_Point_Size}
            fi
            if [ -z "${Layer_Color}" ];then
                Layer_Color=${Layer_Point_Color}
            fi
            gmt psxy ${LayerFile} -J -R -G${Layer_Color} -S${Layer_Size} -K -O -V >> ${Output_File}
        elif [ "`echo ${ShapeTypeIdentify} | grep 'LINE'`" ];then
            if [ -z "${Layer_Size}" ];then
                Layer_Size=${Layer_Line_Size}
            fi
            if [ -z "${Layer_Color}" ];then
                Layer_Color=${Layer_Line_Color}
            fi
            gmt psxy ${LayerFile} -J -R -W${Layer_Size}p,${Layer_Color} -K -O -V >> ${Output_File}
        elif [ "`echo ${ShapeTypeIdentify} | grep 'POLYGON'`" ];then
            if [ -z "${Layer_Size}" ];then
                Layer_Size=${Layer_Polygon_Line_Size}
            fi
            if [ -z "${Layer_Color}" ];then
                Layer_Color=${Layer_Polygon_Line_Color}
            fi
            if [ "${Fill_Color}" ];then
                Fill_Color=-G${Fill_Color}
            fi
            gmt psxy ${LayerFile} -J -R ${Fill_Color} -W${Layer_Size}p,${Layer_Color} -K -O -V >> ${Output_File}
        fi
    done
}

function convert_fig(){
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
    gmt psconvert ${psconvert_T} ${psconvert_A} -P ${Output_File}
}

function plot_velocity(){
    # 產生Configure
    if [ ! -f "${config}" ];then
        define_edge_geo
        define_edge_cpt
        config_default_v

        help_config
        config_gereral
        config_io
        config_psbasemap
        config_basemap_image
        config_psxy_PS
        config_scale
        config_addition_layer
        config_title PS Velocity Plot
        exit 1
    fi

    # 載入參數
    setting_config
    setting_argument
    setting_XYOffset 3 4
    setting_output
    # 底圖設定
    gmt psbasemap -J${psbasemap_J} -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -BWSen+t"${Title}" -Bx${psbasemap_Bx} -By${psbasemap_By} ${X} ${Y} -K -P -V > ${Output_File}

    if [ "${Plot_Basemap}" == "true" ];then
        crop_image
        plot_basemap_image
    else
        echo Skipping plot image.
    fi
    if [ "${Addition_Layers}" ] && [ "${Addition_Layers_Position}" == "front" ];then
        plot_add_layer
    fi

    plot_ps

    if [ "${Addition_Layers}" ] && [ "${Addition_Layers_Position}" == "back" ];then
        plot_add_layer
    fi

    plot_coastline
    plot_legend ps.cpt

    # 封檔
    gmt psxy -R -J -T -O >> ${Output_File}
    convert_fig
}

function plot_deformation(){

    if [ ! -f "${config}" ];then
        config_default_v

        help_config
        config_gereral
        config_io
        config_psbasemap
        config_basemap_image
        config_psxy_PS
        config_scale
        config_title PS Deformation Plot
        exit 1
    fi
    source ${pwd}/${config}
    Output_File=${Output_File}.ps
}

function plot_timeseries(){
    if [ ! -f "${config}" ];then
        Input_X=${Input_Date}
        Input_Y=${Input_Bperp}
        define_edge_time
        config_default_ts
        help_config
        config_gereral
        config_io
        config_psbasemap
        config_psxy_timeseries
        config_title PS Time Series Plot
        exit 1
    fi

    setting_config
    setting_argument
    setting_XYOffset 3 4

    if [ -f "${1}" ];then
        LonLat_list=`cat ${1}`
        for LonLat in ${LonLat_list}
        do
            PS_Center_Lon=`echo ${LonLat} | awk 'BEGIN {FS = ","} {print $1}'`
            PS_Center_Lat=`echo ${LonLat} | awk 'BEGIN {FS = ","} {print $2}'`
            echo "Batch processing...."
            echo "Plotting PS ${PS_Center_Lon} ${PS_Center_Lat}"
        done
    fi

    #計算範圍
    F_Lon=`echo "${PS_Center_Lon}-0.00001" | bc`
    L_Lon=`echo "${PS_Center_Lon}+0.00001" | bc`
    U_Lat=`echo "${PS_Center_Lat}+0.00001" | bc`
    L_Lat=`echo "${PS_Center_Lat}-0.00001" | bc`

    setting_output ${PS_Center_Lon} ${PS_Center_Lat}
    Crop_Identify=0
    until [ "${Crop_Identify}" -eq "1" ]
    do
        F_Lon=`echo "${F_Lon}-0.00001" | bc`
        Distance=`m2ll ${F_Lon} ${PS_Center_Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
        Crop_Identify=`gmt math -Q ${Distance} ${PS_Radius} GE =`
    done
    Crop_Identify=0
    until [ "${Crop_Identify}" -eq "1" ]
    do
        L_Lon=`echo "${L_Lon}+0.00001" | bc`
        Distance=`m2ll ${L_Lon} ${PS_Center_Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
        Crop_Identify=`gmt math -Q ${Distance} ${PS_Radius} GE =`
    done
    Crop_Identify=0
    until [ "${Crop_Identify}" -eq "1" ]
    do
        U_Lat=`echo "${U_Lat}+0.00001" | bc`
        Distance=`m2ll ${PS_Center_Lon} ${U_Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
        Crop_Identify=`gmt math -Q ${Distance} ${PS_Radius} GE =`
    done
    Crop_Identify=0
    until [ "${Crop_Identify}" -eq "1" ]
    do
        L_Lat=`echo "${L_Lat}-0.00001" | bc`
        Distance=`m2ll ${PS_Center_Lon} ${L_Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
        Crop_Identify=`gmt math -Q ${Distance} ${PS_Radius} GE =`
    done
    echo ${F_Lon} ${L_Lon} ${U_Lat} ${L_Lat}
    end=$(date +%s.%N)
    runtime=$(echo "${end} - ${start}" | bc)
    echo "Runtime 1 was ${runtime}"

    #載入座標資料
    echo Load data.
    Input_FilesArray=(`ls -v ${Input_Data}`)
    nl  ${Input_LonLat} | awk '$2>'"${F_Lon}"' && $2<'"${L_Lon}"' && $3<'"${U_Lat}"' && $3>'"${L_Lat}"' {printf("%d %.8f %.8f\n",$1,$2,$3)}' > tmp_Candidates.txt
    
    end=$(date +%s.%N)
    runtime=$(echo "${end} - ${start}" | bc)
    echo "Runtime 2 was ${runtime}"

    PS_Count=`wc -l tmp_Candidates.txt | awk '{print $1}'`
    if [ "${PS_Count}" -eq 0 ];then
        echo "No PS found in select area."
        exit 1
    fi

    Date_Count=`wc -l ${Input_Date} | awk '{print $1}'`
    LineArray=(`cat tmp_Candidates.txt | awk '{printf("%d\n",$1)}'`)
    LonArray=(`cat tmp_Candidates.txt | awk '{printf("%.8f\n",$2)}'`)
    LatArray=(`cat tmp_Candidates.txt | awk '{printf("%.8f\n",$3)}'`)
    DateArray=(`cat ${Input_Date} | awk '{printf("%d\n",$1)}' | gmt gmtconvert -fT`)
    
    gmt gmtset FORMAT_DATE_IN yyyy-mm-dd
    gmt psbasemap -J${psbasemap_J} -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -BWSen+t"${Title}" -Bsx${Map_Bax}Y -Bpxa${Map_Bbx}Of1o+l"Time" -By${psbasemap_By}+l"Displacement (mm)" ${X} ${Y} -K -V > ${Output_File}
    
    # echo Crop data.
    # for (( i=0; i<${Date_Count}; i=i+1 ))
    # do
    #     echo ${Input_FilesArray[${i}]}
    #     awk -v FL="${LineArray[0]}" -v LL="${LineArray[$((PS_Count-1))]}" 'NR >= FL && NR <= LL' ${Input_FilesArray[${i}]} > tmp_${i}.txt
    # done

    echo "Calculate PS inside selected range...."
    PS_Select=0

    for (( i=0; i<${Date_Count}; i=i+1 ))
    do
<<<<<<< HEAD
        Lon=`echo ${LonArray[${i}]} | awk '{printf("%.7e",$1)}'`
        Lat=`echo ${LatArray[${i}]} | awk '{printf("%.7e",$1)}'`
        echo Checking $Lon $Lat
        # Lon_Sub=`gmt math -Q ${Lon} ${PS_Center_Lon} SUB =`
        # Lat_Sub=`gmt math -Q ${Lat} ${PS_Center_Lat} SUB =`
        # r2=`gmt math -Q ${Lon_Sub} ${Lat_Sub} R2 =`
        # R2=`gmt math -Q ${PS_Radius} SQR =`
        Distance=`m2ll ${Lon} ${Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
        Identify=`gmt math -Q ${PS_Radius} ${Distance} GE =`
        if [ "${Identify}" -eq "1" ];then
            echo "> -Z"${i} >> tmp_TS.txt
            echo ${Lon} ${Lat} >> ${Output_File}_${PS_Center_Lon}_${PS_Center_Lat}.txt
            for (( j=0; j<${Date_Count}; j=j+1 ))
            do
                #data=`grep ${Lon}.*${Lat} tmp_${j}.txt | awk '{printf("%.8f\n",$3)}'`
                echo "grep"
                time grep ${Lon}.*${Lat} tmp_${j}.txt | awk '{printf("%.8f\n",$3)}'
                echo "sed"
                time sed "${LineArray[j]}"'!d' ${Input_FilesArray[${i}]} | awk '{printf("%.8f\n",$3)}'
=======
        # echo ${Input_FilesArray[${i}]}
        for (( j=0; j<${PS_Count}; j=j+1 ))
        do
            Lon=`echo ${LonArray[${j}]} | awk '{printf("%.7e",$1)}'`
            Lat=`echo ${LatArray[${j}]} | awk '{printf("%.7e",$1)}'`
            echo Checking ${Lon} ${Lat}
            Distance=`m2ll ${Lon} ${Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
            Identify=`gmt math -Q ${PS_Radius} ${Distance} GE =`
            if [ "${Identify}" -eq "1" ];then
                echo "> -Z"${j} >> tmp_TS_${i}.txt
                echo ${Lon} ${Lat} >> ${Output_File}_${PS_Center_Lon}_${PS_Center_Lat}.txt
>>>>>>> ece94982830a8f6ac9b8402286334603a4b20942
                data=`sed "${LineArray[j]}"'!d' ${Input_FilesArray[${i}]} | awk '{printf("%.8f\n",$3)}'`
                line=${line}\ ${data}
                echo ${DateArray[${j}]} ${data} ${i} >> tmp_TS.txt
                # for (( j=0; j<${Date_Count}; j=j+1 ))
                # do
                #     data=`grep ${Lon}.*${Lat} tmp_${j}.txt | awk '{printf("%.8f\n",$3)}'`
                #     line=${line}\ ${data}
                #     echo ${DateArray[${j}]} ${data} ${i} >> tmp_TS.txt
                # done
                echo ${line} >> tmp_TS_Data.txt
                PS_Select=$((PS_Select+1))
                unset line
                if [ "$Plot_single_PS" == "true" ];then
                    gmt psxy -R -J -S${psxy_Size} -Ccategorical.cpt -O -K tmp_TS.txt >> ${Output_File}
                fi
            fi
        done
    done
    # for (( i=0; i<${PS_Count}; i=i+1 ))
    # do
    #     Lon=`echo ${LonArray[${i}]} | awk '{printf("%.7e",$1)}'`
    #     Lat=`echo ${LatArray[${i}]} | awk '{printf("%.7e",$1)}'`
    #     echo Checking $Lon $Lat
    #     # Lon_Sub=`gmt math -Q ${Lon} ${PS_Center_Lon} SUB =`
    #     # Lat_Sub=`gmt math -Q ${Lat} ${PS_Center_Lat} SUB =`
    #     # r2=`gmt math -Q ${Lon_Sub} ${Lat_Sub} R2 =`
    #     # R2=`gmt math -Q ${PS_Radius} SQR =`
    #     r2=`m2ll ${Lon} ${Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
    #     Identify=`gmt math -Q ${PS_Radius} ${r2} GE =`
    #     if [ "${Identify}" -eq "1" ];then
    #         echo "> -Z"${i} >> tmp_TS.txt
    #         echo ${Lon} ${Lat} >> ${Output_File}_${PS_Center_Lon}_${PS_Center_Lat}.txt
    #         for (( j=0; j<${Date_Count}; j=j+1 ))
    #         do
    #             data=`grep ${Lon}.*${Lat} tmp_${j}.txt | awk '{printf("%.8f\n",$3)}'`
    #             line=${line}\ ${data}
    #             echo ${DateArray[${j}]} ${data} ${i} >> tmp_TS.txt
    #         done
    #         echo ${line} >> tmp_TS_Data.txt
    #         PS_Select=$((PS_Select+1))
    #         unset line
    #         if [ "$Plot_single_PS" == "true" ];then
    #             gmt psxy -R -J -S${psxy_Size} -Ccategorical.cpt -O -K tmp_TS.txt >> ${Output_File}
    #         fi
    #     else
    #         continue
    #     fi
    # done
    echo -e "\e[1;31mTotal ${PS_Select} PS selected.\e[0m"
    # 繪製平均曲線與誤差
    MeanArray=(`gmt math -Ca -S tmp_TS_Data.txt MEAN =`)
    StdArray=(`gmt math -Ca -S tmp_TS_Data.txt STD =`)
    echo "> -Z0" >> tmp_TS_Mean_Error.txt
    echo "Drawing error bar...."
    for (( j=0; j<${Date_Count}; j=j+1 ))
    do
        echo ${DateArray[${j}]} ${MeanArray[${j}]} ${StdArray[${j}]} >> tmp_TS_Mean_Error.txt
    done
    gmt psxy -R -J ${psxy_W} -O -K tmp_TS_Mean_Error.txt >> ${Output_File}
    gmt psxy -R -J -S${psxy_Size_Mean} -G${psxy_G} ${errorbar} -O -K tmp_TS_Mean_Error.txt >> ${Output_File}
    echo "75 98 Central Lon : ${PS_Center_Lon}" | gmt pstext -R0/100/0/100 -J -F+f16p+jTL -O -K >> ${Output_File}
    echo "75 92 Central Lat : ${PS_Center_Lat}" | gmt pstext -R -J -F+f16p+jTL -O -K >> ${Output_File}
    echo "75 86 Selected PSs : ${PS_Select}" | gmt pstext -R -J -F+f16p+jTL -O -K >> ${Output_File}
    
    # 封檔
    gmt psxy -R -J -T -O >> ${Output_File}
    convert_fig

    #刪除暫存檔
    rm tmp_*
}

function plot_gps(){
    if [ ! -f "${config}" ];then
        config_default_gps
        help_config
        config_gereral
        config_io
        config_psbasemap
        config_basemap_image
        config_psxy_PS
        config_scale
        config_title PS Time Series Plot
        exit 1
    fi
    
    Output_File=${Output_File}.ps
    setting_config
}

function plot_image(){
    if [ ! -f "${config}" ];then
        define_edge_geo
        config_default_v

        help_config
        config_gereral
        config_io
        config_psbasemap
        config_basemap_image
        config_addition_layer
        config_title
        exit 1
    fi

    setting_config
    setting_argument
    setting_XYOffset 3 4
    setting_output

    gmt psbasemap -J${psbasemap_J} -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -BWSen+t"${Title}" -Bx${psbasemap_Bx} -By${psbasemap_By} ${X} ${Y} -K -P -V > ${Output_File}

    crop_image
    plot_basemap_image
    
    if [ "${Addition_Layers}" ];then
        plot_add_layer
    fi

    plot_coastline

    # 封檔
    gmt psxy -R -J -T -O >> ${Output_File}
    convert_fig
}

function plot_baseline(){
    Input_X=${Input_Date}
    Input_Y=${Input_Bperp}
    if [ ! -f "${config}" ];then
        define_edge_time
        echo "Please setup ${config} for input."
        echo
        echo "# Configure for gmt_plot, please visit GMT website for more detail." > ${config}
        config_default_ts
        config_gereral
        config_io
        config_psbasemap
        config_psxy_baseline
        config_title Baseline Plot
        exit 1
    fi
    setting_config
    setting_argument
    setting_XYOffset 3 3
    setting_output
    Imgs_Count=`wc -l ${Input_Date} | awk '{print $1}'`
    BperpArray=(`cat ${Input_Bperp} | awk '{printf("%d\n",$1)}'`)
    DateArray=(`cat ${Input_Date} | awk '{printf("%d\n",$1)}' | gmt gmtconvert -fT`)
    
    gmt gmtset FORMAT_DATE_IN yyyy-mm-dd
    gmt psbasemap -J${psbasemap_J} -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -BWSen+t"${Title}" -Bsx${Map_Bax}Y -Bpxa${Map_Bbx}Of1o+l"Time" -By${psbasemap_By}+l"Bperp (m)" ${X} ${Y} -K -V > ${Output_File}
    cp ${Output_File} temp.ps
    rm ${Output_File}

    echo "DInSAR"
    setting_output dinsar
    cp temp.ps ${Output_File}
    Ifgs_Count=`wc -l ${Input_Bperp} | awk '{print $1}'`
    for (( i=0; i<${Ifgs_Count}; i=i+1 ))
    do
        if [ "${BperpArray[${i}]}" -eq 0 ];then
            Master=${DateArray[${i}]}
            echo "Master image is ${Master}."
        fi
    done
    for (( i=0; i<${Ifgs_Count}; i=i+1 ))
    do
        echo "${DateArray[${i}]} ${BperpArray[${i}]}"
        echo ${DateArray[${i}]} ${BperpArray[${i}]} | gmt psxy -R -J -Fr${Master}/0 ${psxy_W} -O -K >> ${Output_File}
    done
    for (( i=0; i<${Imgs_Count}; i=i+1 ))
    do
        if [ "${DateArray[${i}]}" == "${Master}" ];then
            echo ${DateArray[${i}]} ${BperpArray[${i}]} | gmt psxy -R -J -S${M_psxy_Size} -G${M_psxy_G} -O -K >> ${Output_File}
        else
            echo ${DateArray[${i}]} ${BperpArray[${i}]} | gmt psxy -R -J -S${psxy_Size} -G${psxy_G} -O -K >> ${Output_File}
        fi
    done
    gmt psxy -R -J -T -O >> ${Output_File}
    convert_fig
    
    if [ -f "${Input_SBAS}" ];then
        echo "SBAS"
        setting_output sbas
        cp temp.ps ${Output_File}
        gmt gmtset FORMAT_DATE_IN yyyymmdd
        Ifgs_Count=`wc -l ${Input_SBAS} | awk '{print $1}'`
        MasterDatesArray=(`cat ${Input_SBAS} | awk '{printf("%d\n",$1)}' | gmt gmtconvert -fT`)
        SlaveDatesArray=(`cat ${Input_SBAS} | awk '{printf("%d\n",$2)}' | gmt gmtconvert -fT`)
        gmt gmtset FORMAT_DATE_IN yyyy-mm-dd
        Dates=${MasterDates}" "${SlaveDates}
        for (( i=0; i<${Ifgs_Count}; i=i+1 ))
        do
            MasterDate=${MasterDatesArray[${i}]}
            SlaveDate=${SlaveDatesArray[${i}]}
            for (( j=0; j<${Imgs_Count}; j=j+1 ))
            do
                if [ "${MasterDate}" == "${DateArray[${j}]}" ];then
                    MasterBperp=${BperpArray[${j}]}
                elif [ "${SlaveDate}" == "${DateArray[${j}]}" ];then
                    SlaveBperp=${BperpArray[${j}]}
                fi
            done
            echo "${MasterDate} ${SlaveDate}"
            echo ${SlaveDate} ${SlaveBperp} | gmt psxy -R -J -Fr${MasterDate}/${MasterBperp} ${psxy_W} -O -K >> ${Output_File}
        done
        for (( i=0; i<${Imgs_Count}; i=i+1 ))
        do
            echo ${DateArray[${i}]} ${BperpArray[${i}]} | gmt psxy -R -J -S${psxy_Size} -G${psxy_G} -O -K >> ${Output_File}
        done
        gmt psxy -R -J -T -O >> ${Output_File}
        convert_fig
    fi
    rm temp.ps
}

start=$(date +%s.%N)

# 讀取設定檔
pwd=`pwd`
if [ -z "${1}" ];then
    help
    exit 1
else
    mode=${1}
fi
Input_config=${2}

define_io
define_configure

if [ "${mode}" == "velocity" ];then
    plot_velocity
elif [ "${mode}" == "deformation" ];then
    plot_deformation
elif [ "${mode}" == "timeseries" ];then
    plot_timeseries ${3}
elif [ "${mode}" == "baseline" ];then
    plot_baseline
elif [ "${mode}" == "gps" ];then
    plot_gps
elif [ "${mode}" == "image" ];then
    plot_image
else
    help
fi

end=$(date +%s.%N)
runtime=$(echo "${end} - ${start}" | bc)
echo "Runtime was ${runtime}"
