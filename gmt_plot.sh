#!/bin/bash
# InSAR GMT製圖程序
#
#整合與模組化各項製圖程序
# 2018/07/24 CV 初版
#
function help(){
    echo
    echo "GMT plot program by Constantine VI."
    echo "Support mode:"
    echo "  velocity: plot PSI mean velocity"
    echo "  deformation: plot PSI deformation"
    echo "  timeseries: plot PSI time series in select area"
    echo "  baseline: plot interferogram baseline"
    echo "  image: plot interferogram/DEM/optical images"
    echo "  gps: plot GPS time series"
    echo "  gpslos: plot projected GPS time series"
    echo "  profile: plot profile of PS mean velocity"
    echo
    echo "Usage: gmt_plot.sh [Mode] [Congifure File] [Input File]"
}

function help_config(){
    echo "Please setup ${config} for input."
    echo
}

function define_io(){
    Input_Data=${1}
    Input_Date=date.txt
    Input_Bperp=bperp.txt
    Input_SBAS=small_baselines.list
    Input_LonLat=ps_ll.txt
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
    if [ "${mode}" == "velocity" ] || [ "${mode}" == "image" ];then
        echo "FORMAT_GEO_MAP=ddd.xxF" >> ${config}
        echo "MAP_FRAME_TYPE=fancy" >> ${config}
        echo "MAP_FRAME_PEN=thicker" >> ${config}
        echo "MAP_ANNOT_OFFSET=2p" >> ${config}
        echo "FONT=Times-Roman" >> ${config}
        echo "FONT_LOGO=Times-Roman" >> ${config}
        echo "FONT_TITLE=18p,Times-Roman" >> ${config}
        echo "FONT_LABEL=12p,Times-Roman" >> ${config}
        echo "FONT_ANNOT_PRIMARY=12p,Times-Roman" >> ${config}
    elif [ "${mode}" == "deformation" ];then
        echo "FORMAT_GEO_MAP=ddd.xxF" >> ${config}
        echo "MAP_FRAME_TYPE=plain" >> ${config}
        echo "MAP_FRAME_PEN=thicker" >> ${config}
        echo "FONT=Times-Roman" >> ${config}
        echo "FONT_LOGO=Times-Roman" >> ${config}
        echo "FONT_ANNOT_PRIMARY=6p,Times-Roman" >> ${config}
    elif [ "${mode}" == "timeseries" ] || [ "${mode}" == "gpslos" ];then
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
    elif [ "${mode}" == "profile" ];then
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
    echo "" >> ${config}
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
    echo "Plot_Mean_PS_W=false" >> ${config}
    echo "psxy_W=1p" >> ${config}
    echo "## 設定Errorbar" >> ${config}
    echo "Plot_Errorbar=false" >> ${config}
    echo "Errorbar_W=1p" >> ${config}

    echo "## 設定PS中心座標與範圍，範圍單位:m" >> ${config}
    echo "PS_Center_Lon=" >> ${config}
    echo "PS_Center_Lat=" >> ${config}
    echo "PS_Radius=10" >> ${config}
    echo "" >> ${config}
}

function config_gps_timeseries(){
    echo "# psxy setting" >> ${config}
    echo "## 設定資料點樣式與大小，格式=[樣式代號][大小]，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
    echo "psxy_Size=c0.1" >> ${config}
    echo "psxy_LonG=red" >> ${config}
    echo "psxy_LatG=green" >> ${config}
    echo "psxy_HG=blue" >> ${config}
    echo "## 設定起點日期之值為0" >> ${config}
    echo "StartDate=" >> ${config}
    echo "" >> ${config}
}

function config_psxy_profile(){
    echo "# psxy setting" >> ${config}
    echo "## 設定資料點樣式與大小，格式=[樣式代號][大小]，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
    echo "## 是否繪製地形" >> ${config}
    echo "Plot_topography=true" >> ${config}
    echo "## 設定連線樣式" >> ${config}
    echo "psxy_W=1p" >> ${config}
    echo "## 是否繪製平均速度場" >> ${config}
    echo "Plot_Mean_V=ture" >> ${config}
    echo "psxy_Size_Mean=c0.2" >> ${config}
    echo "psxy_G=black" >> ${config}

    echo "## 設定起始與終點座標" >> ${config}
    echo "StartLon=" >> ${config}
    echo "StartLat=" >> ${config}
    echo "EndLon=" >> ${config}
    echo "EndLat=" >> ${config}
    echo "## 設定剖面寬度(單位：公里)" >> ${config}
    echo "Profile_Width=0.05" >> ${config}
    echo "" >> ${config}
}

function config_colorbar(){
    echo "# colorbar setting" >> ${config}
    echo "## 圖例樣式" >> ${config}
    echo "colorbar_position=BC  #R=右 L=左/T=上 B=下" >> ${config}
    echo "colorbar_width=10" >> ${config}
    echo "colorbar_high=0.5" >> ${config}
    echo "colorbar_size_unit=c" >> ${config}
    echo "colorbar_anchor_point=TC  #R=右 L=左/T=上 B=下" >> ${config}
    echo "colorbar_direction=h  #h=horizontal v=vertical" >> ${config}
    echo "colorbar_offset_X=0  #單位：公分" >> ${config}
    echo "colorbar_offset_Y=1  #單位：公分" >> ${config}
    echo "## 圖例文字說明" >> ${config}
    echo "colorbar_Label=\"${colorbar_Label}\"" >> ${config}
    echo "## 設定圖例坐標軸刻度間隔" >> ${config}
    echo "colorbar_scale_Ba=50" >> ${config}
    echo "colorbar_scale_Bf=10" >> ${config}
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

function config_map_objects(){
    echo "# 地圖物件" >> ${config}
    echo "## 是否繪製海岸線(海岸線資料由GMT提供)" >> ${config}
    echo "CoastLine=true" >> ${config}
    echo "## 是否繪製指北針" >> ${config}
    echo "Compass=false" >> ${config}
    echo "## 設定指北針樣式" >> ${config}
    echo "Compass_position=LT  #R=右 L=左/T=上 B=下" >> ${config}
    echo "Compass_offset_X=1  #單位：公分" >> ${config}
    echo "Compass_offset_Y=2  #單位：公分" >> ${config}
    echo "Compass_width=2  #單位：公分" >> ${config}
    echo "## 是否繪製比例尺" >> ${config}
    echo "Scale=true" >> ${config}
    echo "## 設定比例尺樣式" >> ${config}
    echo "Scale_position=RB  #R=右 L=左/T=上 B=下" >> ${config}
    echo "Scale_offset_X=1  #單位：公分" >> ${config}
    echo "Scale_offset_Y=1  #單位：公分" >> ${config}
    echo "Scale_length=10 #單位：公里" >> ${config}
    echo "Scale_align=t  #比例尺標籤位置 r/l/t/b" >> ${config}
    echo "" >> ${config}
}

function config_title(){
    argvs=$@
    for argv in ${argvs}
    do
        if [ "${Title}" ];then
            Title="${Title} ${argv}"
        else
            Title="${argv}"
        fi
    done
    echo "# title setting" >> ${config}
    echo "Title=\"${Title}\" " >> ${config}
}

function setting_default_map_plot(){
    Map_Projection=M
    Map_Width=6
    Map_Offset_Y=4
    Map_Bax=1
    Map_Bbx=0.2
    Map_Bay=1
    Map_Bby=0.2
    colorbar_Label="LOS Velocity (mm/yr)"
}

function setting_default_xy_plot(){
    Map_Projection=X
    Map_Width=9
    Map_High=4
    Map_Bax=1
    Map_Bbx=3
    Map_Bay=50
    Map_Bby=10
}

function read_config(){
    source ${pwd}/${config}
    gmt gmtset ${gmt_config}
}

function define_output(){
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

function define_argument(){
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

    if [ "${psxy_W}" == "-" ];then
        psxy_W=-W${psxy_W}
    elif [ ! -z "${psxy_W}" ];then
        psxy_W=-W${psxy_W}
    fi

    if [ "${Plot_Errorbar}" == "true" ];then
        errorbar=-Ey/${Errorbar_W}
    fi
}

function define_xy_offset(){
    if [ $# -ne 0 ];then
        X=-X${1}
        Y=-Y${2}
    fi
}

function read_edge_x(){
    if [ -f "${1}" ];then
        Edge_Left=`cat ${1} | awk '{printf("%'${2}'\n",$'${3}')}' | gmt info -I${4} -C | cut -f1`
        Edge_Right=`cat ${1} | awk '{printf("%'${2}'\n",$'${3}')}' | gmt info -I${4} -C | cut -f2`
    fi
}

function read_edge_y(){
    if [ -f "${1}" ];then
        Edge_Lower=`cat ${1} | awk '{printf("%'${2}'\n",$'${3}')}' | gmt info -I${4} -C | cut -f1`
        Edge_Upper=`cat ${1} | awk '{printf("%'${2}'\n",$'${3}')}' | gmt info -I${4} -C | cut -f2`
        if [ "${5}" == "fix" ];then
            Edge_Y=`gmt math -Q ${Edge_Lower} ${Edge_Upper} MAX =`
            Edge_Lower=-${Edge_Y}
            Edge_Upper=${Edge_Y}
        fi
    else
        Edge_Lower=-${1}
        Edge_Upper=${1}
    fi
}

function read_edge_x_time(){
    gmt gmtset FORMAT_DATE_IN yyyymmdd FORMAT_DATE_OUT yyyy-mm-dd
    Edge_Left=`cat ${1} | awk '{printf("%d\n",$'${2}')}' | gmt info -fT -I1 -C | cut -f1`
    Edge_Right=`cat ${1} | awk '{printf("%d\n",$'${2}')}' | gmt info -fT -I1 -C | cut -f2`
}

function read_edge_time_GPS(){
    gmt gmtset FORMAT_DATE_IN yyyy-jjj FORMAT_DATE_OUT yyyy-jjj
    First_YearDate=`cat ${Input_Data} | awk '{printf("%.8f\n",$1)}' | gmt info -C | cut -f1`
    Last_YearDate=`cat ${Input_Data} | awk '{printf("%.8f\n",$1)}' | gmt info -C | cut -f2`
    FirstYear=`cat ${Input_Data} | awk '{printf("%d\n",$1)}' | gmt info -C | cut -f1`
    FirstDay=`cat ${Input_Data} | awk '{printf("%.8f\n",$1)}' | gmt info -C | cut -f1`
    FirstDay=`gmt math -Q ${FirstDay} ${FirstYear} SUB =`
    FirstDay=`gmt math -Q ${FirstDay} 365 MUL 1 ADD = | awk '{printf("%d\n",$1)}'`
    LastYear=`cat ${Input_Data} | awk '{printf("%d\n",$1)}' | gmt info -C | cut -f2`
    LastDay=`cat ${Input_Data} | awk '{printf("%.8f\n",$1)}' | gmt info -C | cut -f2`
    LastDay=`gmt math -Q ${LastDay} ${LastYear} SUB =`
    LastDay=`gmt math -Q ${LastDay} 365 MUL 1 ADD = | awk '{printf("%d\n",$1)}'`
    gmt gmtset FORMAT_DATE_OUT yyyy-mm-dd
    Edge_Left=`echo ${FirstYear}-${FirstDay} | gmt info -fT -I1 -C | cut -f1`
    Edge_Right=`echo ${LastYear}-${LastDay} | gmt info -fT -I1 -C | cut -f1`
}

function define_edge_time_GPS(){
    gmt gmtset FORMAT_DATE_IN yyyy-mm-dd FORMAT_DATE_OUT yyyy-jjj
    FirstYear=`echo ${Edge_Left} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$1)}'`
    FirstDay=`echo ${Edge_Left} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$2)}'`
    FirstYearDay=`gmt math -Q ${FirstDay} 365 DIV =`
    First_YearDate=`gmt math -Q ${FirstYearDay} ${FirstYear} ADD =`
    LastYear=`echo ${Edge_Right} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$1)}'`
    LastDay=`echo ${Edge_Right} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$2)}'`
    LastYearDay=`gmt math -Q ${LastDay} 365 DIV =`
    Last_YearDate=`gmt math -Q ${LastYearDay} ${LastYear} ADD =`
}

function read_edge_cpt(){
    max_cpt=`cat ${Input_Data} | awk '{printf("%f\n",$3)}' | gmt info -I10 -C | cut -f2`
    min_cpt=`cat ${Input_Data} | awk '{printf("%f\n",$3)}' | gmt info -I10 -C | cut -f1`
    max_cpt_abs=`gmt math -Q ${max_cpt} ABS =`
    min_cpt_abs=`gmt math -Q ${min_cpt} ABS =`
    cpt=`gmt math -Q ${max_cpt_abs} ${min_cpt_abs} MAX =`
}

function crop_image(){
    Basemap_Output=${Basemap_Output}_${Basemap_Type}.tif
    if [ -f "${Basemap_Output}" ];then
        basemap_crop_xmin=`gmt grdinfo ${Basemap_Output} | grep 'x_min' | awk '{print $3}'`
        basemap_crop_xmax=`gmt grdinfo ${Basemap_Output} | grep 'x_min' | awk '{print $5}'`
        basemap_crop_ymin=`gmt grdinfo ${Basemap_Output} | grep 'y_min' | awk '{print $3}'`
        basemap_crop_ymax=`gmt grdinfo ${Basemap_Output} | grep 'y_min' | awk '{print $5}'`
        First_Lon_Sub=`gmt math -Q ${1} ${basemap_crop_xmin} SUB 0 EQ =`
        Last_Lon_Sub=`gmt math -Q ${2} ${basemap_crop_xmax} SUB 0 EQ =`
        Lower_Lat_Sub=`gmt math -Q ${3} ${basemap_crop_ymin} SUB 0 EQ =`
        Upper_Lat_Sub=`gmt math -Q ${4} ${basemap_crop_ymax} SUB 0 EQ =`
        if [ "${First_Lon_Sub}" -eq 0 ] || [ "${Last_Lon_Sub}" -eq 0 ] ||[ "${Lower_Lat_Sub}" -eq 0 ] ||[ "${Upper_Lat_Sub}" -eq 0 ];then
            gdal_translate -projwin ${1} ${2} ${3} ${4} -of GTiff ${Basemap_Path} ${Basemap_Output}
        fi
    else
        gdal_translate -projwin ${1} ${2} ${3} ${4} -of GTiff ${Basemap_Path} ${Basemap_Output}
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

function plot_legend_colorbar(){
    if [ "${colorbar_direction}" ];then
        colorbar_direction=+${colorbar_direction}
    fi
    colorbar_scale_B=a${colorbar_scale_Ba}f${colorbar_scale_Bf}
    gmt psscale -C${1} -J -R -Dj${colorbar_position}+w${colorbar_width}/${colorbar_high}${colorbar_size_unit}+j${colorbar_anchor_point}${colorbar_direction}+o${colorbar_offset_X}/${colorbar_offset_Y}c -B${colorbar_scale_B}+l"${colorbar_Label}" -K -O -P -V >> ${Output_File}
}

function plot_add_layer(){
    for Addition_Layer in ${Addition_Layers}
    do
        LayerFile=`echo ${Addition_Layer} | awk 'BEGIN {FS = ","} {print $1}'`
        LayerFileName=`echo ${LayerFile} | sed 's/.*\///g' | sed 's/\..*//g'`
        LayerFormat=`echo ${LayerFile} | sed 's/.*\.//g'`
        echo Processing ${LayerFileName}
        if [ "${LayerFormat}" == "shp" ];then
            ogr2ogr -f gmt ${LayerFileName}.gmt ${LayerFile}
            LayerFile=${LayerFileName}.gmt
            ShapeTypeIdentify=`nl ${LayerFile} | sed -n '1p'`
        elif [ "${LayerFormat}" == "gmt" ];then
            ShapeTypeIdentify=`nl ${LayerFile} | sed -n '1p'`
        elif [ "${LayerFormat}" == "txt" ];then
            ShapeTypeIdentify=POINT
        else
            echo "Not support ${LayerFormat} format, skip layer plotting."
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

function project_layer(){
    for Addition_Layer in ${Addition_Layers}
    do
        LayerFile=`echo ${Addition_Layer} | awk 'BEGIN {FS = ","} {print $1}'`
        LayerFileName=`echo ${LayerFile} | sed 's/.*\///g' | sed 's/\..*//g'`
        LayerFormat=`echo ${LayerFile} | sed 's/.*\.//g'`
        echo Processing ${LayerFileName}
        if [ "${LayerFormat}" == "shp" ];then
            ogr2ogr -f gmt ${LayerFileName}.gmt ${LayerFile}
            LayerFile=${LayerFileName}.gmt
            ShapeTypeIdentify=`nl ${LayerFile} | sed -n '1p'`
        elif [ "${LayerFormat}" == "gmt" ];then
            ShapeTypeIdentify=`nl ${LayerFile} | sed -n '1p'`
        elif [ "${LayerFormat}" == "txt" ];then
            ShapeTypeIdentify=POINT
        else
            echo "Not support ${LayerFormat} format, skip layer plotting."
        fi

        Layer_Size=`echo ${Addition_Layer} | awk 'BEGIN {FS = ","} {print $2}'`
        Layer_Color=`echo ${Addition_Layer} | awk 'BEGIN {FS = ","} {print $3}'`
        if [ -z "${Layer_Size}" ];then
            Layer_Size=${Layer_Point_Size}
        fi
        if [ -z "${Layer_Color}" ];then
            Layer_Color=${Layer_Point_Color}
        fi
        LineLayerFile=`wc -l ${LayerFile} | awk '{print $1}'`
        echo "Project ${LayerFile} into tmp_${LayerFile}_profile.gmt files"
        for (( i=1; i<=${LineLayerFile}; i=i+1 ))
        do
            if [ -z "`cat ${LayerFile} | sed -n ''${i}' p' | grep "#"`" ] && [ -z "`cat ${LayerFile} | sed -n ''${i}' p' | grep ">"`" ];then
                if [ -z "${StartLon}" ] && [ -z "${StartLat}" ];then
                echo AAAAAAAA
                    StartLon=`cat ${LayerFile} | sed -n ''${i}' p' | awk '{print $1}'`
                    StartLat=`cat ${LayerFile} | sed -n ''${i}' p' | awk '{print $2}'`
                elif [ -z "${EndLon}" ] && [ -z "${EndLat}" ];then
                echo BBBBBBBB
                    EndLon=`cat ${LayerFile} | sed -n ''${i}' p' | awk '{print $1}'`
                    EndLat=`cat ${LayerFile} | sed -n ''${i}' p' | awk '{print $2}'`
                    start=${StartLon}/${StartLat}
                    end=${EndLon}/${EndLat}
                    gmt project ${Input_Data} -C${start} -E${end} -W-${Profile_Width}/${Profile_Width} -Lw -Fxypz -Q >> tmp_${LayerFile}_profile.gmt
                else
                echo CCCCCCCC
                    StartLon=${EndLon}
                    StartLat=${EndLat}
                    EndLon=`cat ${LayerFile} | sed -n ''${i}' p' | awk '{print $1}'`
                    EndLat=`cat ${LayerFile} | sed -n ''${i}' p' | awk '{print $2}'`
                    start=${StartLon}/${StartLat}
                    end=${EndLon}/${EndLat}
                    LineLast=`wc -l tmp_${LayerFile}_profile.gmt | awk '{print $1}'`
                    Qdistance=`cat tmp_${LayerFile}_profile.gmt | sed -n ''${LineLast}' p' | awk '{print $3}'`
                    gmt project ${Input_Data} -C${start} -E${end} -W-${Profile_Width}/${Profile_Width} -Lw -Fxypz -S -Q > tmp_profile.gmt
                    cat tmp_profile.gmt | awk '{printf("%s\t%s\t%s\t%s\n",$1,$2,($3+'${Qdistance}'),$4)}' >> tmp_${LayerFile}_profile.gmt
                fi
            else
                unset StartLon
                unset StartLat
                unset EndLon
                unset EndLat
            fi
        done
        gmt psxy tmp_${LayerFile}_profile.gmt -i2,3 -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -J -BW -By${psbasemap_By}+l"LOS Velocity (mm/year)" -S${Layer_Size} -G${Layer_Color} -O -K >> ${Output_File}
        unset StartLon
        unset StartLat
        unset EndLon
        unset EndLat
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
        define_io ps_mean_v.xy
        read_edge_x ${Input_LonLat} f 1 0.1
        read_edge_y ${Input_LonLat} f 2 0.1
        read_edge_cpt
        setting_default_map_plot

        help_config
        config_gereral
        config_io
        config_psbasemap
        config_basemap_image
        config_psxy_PS
        config_colorbar
        config_addition_layer
        config_map_objects
        config_title PS Velocity Plot
        exit 1
    fi

    # 載入參數
    read_config
    define_argument
    define_xy_offset 3 4
    define_output
    # 底圖設定
    gmt psbasemap -J${psbasemap_J} -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -BWSen+t"${Title}" -Bx${psbasemap_Bx} -By${psbasemap_By} ${X} ${Y} -K -P -V > ${Output_File}

    if [ "${Plot_Basemap}" == "true" ];then
        crop_image ${Edge_Left} ${Edge_Upper} ${Edge_Right} ${Edge_Lower}
        plot_basemap_image
    else
        echo Skipping plot image.
    fi
    if [ "${Addition_Layers}" ] && [ "${Addition_Layers_Position}" == "back" ];then
        plot_add_layer
    fi

    plot_ps

    if [ "${Addition_Layers}" ] && [ "${Addition_Layers_Position}" == "front" ];then
        plot_add_layer
    fi

    if [ "${CoastLine}" == "true" ];then
        plot_coastline
    fi
    if [ "${Compass}" == "true" ];then
        gmt psbasemap -R -J -O -K -Tdj${Compass_position}+w${Compass_width}c+f+l,,,N+o${Compass_offset_X}c/${Compass_offset_Y}c -F+c0.2c/0.2c/0.2c/1c+gwhite@50+r0.2c >> ${Output_File}
    fi
    if [ "${Scale}" == "true" ];then
        gmt psbasemap -R -J -O -K -Lj${Scale_position}+c${Edge_Lower}+w${Scale_length}k+f+o${Scale_offset_X}c/${Scale_offset_Y}c+u+a${Scale_align} -F+gwhite@50 >> ${Output_File}
    fi
    
    plot_legend_colorbar ps.cpt
    # 封檔
    gmt psxy -R -J -T -O >> ${Output_File}
    convert_fig
}

function plot_deformation(){

    if [ ! -f "${config}" ];then
        setting_default_map_plot
        define_io ps_u-dmo_r0.*.xy
        help_config
        config_gereral
        config_io
        config_psbasemap
        config_basemap_image
        config_psxy_PS
        config_colorbar
        config_title PS Deformation Plot
        exit 1
    fi
    source ${pwd}/${config}
    Output_File=${Output_File}.ps
}

function plot_timeseries(){
    if [ ! -f "${config}" ];then
        define_io ps_u-dmo_r0.\*.xy
        read_edge_x_time ${Input_Date} 1
        read_edge_y 100
        setting_default_xy_plot
        help_config
        config_gereral
        config_io
        config_psbasemap
        config_psxy_timeseries
        config_title PS Time Series Plot
        exit 1
    fi

    read_config
    define_argument
    define_xy_offset 3 4
    
    if [ "${1}" ] && [ "${2}" ];then
        PS_Center_Lon=${1}
        PS_Center_Lat=${2}
    fi
    #計算範圍
    F_Lon=`echo "${PS_Center_Lon}-0.00001" | bc`
    L_Lon=`echo "${PS_Center_Lon}+0.00001" | bc`
    U_Lat=`echo "${PS_Center_Lat}+0.00001" | bc`
    L_Lat=`echo "${PS_Center_Lat}-0.00001" | bc`
    define_output ${PS_Center_Lon} ${PS_Center_Lat}
    Crop_Identify=0
    until [ "${Crop_Identify}" -eq "1" ]
    do
        F_Lon=`echo "${F_Lon}-0.00001" | bc`
        Distance=`lonlat2m ${F_Lon} ${PS_Center_Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
        Crop_Identify=`gmt math -Q ${Distance} ${PS_Radius} GE =`
    done
    Crop_Identify=0
    until [ "${Crop_Identify}" -eq "1" ]
    do
        L_Lon=`echo "${L_Lon}+0.00001" | bc`
        Distance=`lonlat2m ${L_Lon} ${PS_Center_Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
        Crop_Identify=`gmt math -Q ${Distance} ${PS_Radius} GE =`
    done
    Crop_Identify=0
    until [ "${Crop_Identify}" -eq "1" ]
    do
        U_Lat=`echo "${U_Lat}+0.00001" | bc`
        Distance=`lonlat2m ${PS_Center_Lon} ${U_Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
        Crop_Identify=`gmt math -Q ${Distance} ${PS_Radius} GE =`
    done
    Crop_Identify=0
    until [ "${Crop_Identify}" -eq "1" ]
    do
        L_Lat=`echo "${L_Lat}-0.00001" | bc`
        Distance=`lonlat2m ${PS_Center_Lon} ${L_Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
        Crop_Identify=`gmt math -Q ${Distance} ${PS_Radius} GE =`
    done

    #載入座標資料
    echo Load data.
    Input_FilesArray=(`ls -v ${Input_Data}`)
    cat ${Input_LonLat} | awk '$1>'"${F_Lon}"' && $1<'"${L_Lon}"' && $2<'"${U_Lat}"' && $2>'"${L_Lat}" > tmp_Candidates.txt

    PS_Count=`wc -l tmp_Candidates.txt | awk '{print $1}'`
    if [ "${PS_Count}" -eq 0 ];then
        echo -e "\e[1;31mNo PS found in select area.\e[0m"
        rm tmp_*
        return 1
    fi

    Date_Count=`wc -l ${Input_Date} | awk '{print $1}'`
    LonArray=(`cat tmp_Candidates.txt | awk '{print $1}'`)
    LatArray=(`cat tmp_Candidates.txt | awk '{print $2}'`)
    DateArray=(`cat ${Input_Date} | awk '{printf("%d\n",$1)}' | gmt gmtconvert -fT`)
    
    gmt gmtset FORMAT_DATE_IN yyyy-mm-dd
    gmt psbasemap -J${psbasemap_J} -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -BWSen+t"${Title}" -Bsx${Map_Bax}Y -Bpxa${Map_Bbx}Of1o+l"Time" -By${psbasemap_By}+l"LOS Displacement (mm)" ${X} ${Y} -K -V > ${Output_File}

    echo "Calculate PS inside selected range...."
    PS_Select=0
    for (( i=0; i<${PS_Count}; i=i+1 ))
    do
        Lon=`echo ${LonArray[${i}]} | awk '{print $1}'`
        Lat=`echo ${LatArray[${i}]} | awk '{print $1}'`
        echo Checking ${Lon} ${Lat}
        Distance=`lonlat2m ${Lon} ${Lat} ${PS_Center_Lon} ${PS_Center_Lat}`
        Identify=`gmt math -Q ${PS_Radius} ${Distance} GE =`
        if [ "${Identify}" -eq "1" ];then
            echo "> -Z"${i} >> tmp_TS.txt
            echo ${Lon} ${Lat} >> ${Output_File}_${PS_Center_Lon}_${PS_Center_Lat}.txt
            for (( j=0; j<${Date_Count}; j=j+1 ))
            do
                data=`grep ${Lon}.*${Lat} ${Input_FilesArray[${j}]} | awk '{printf("%.8f\n",$3)}'`
                line=${line}\ ${data}
                echo ${DateArray[${j}]} ${data} ${i} >> tmp_TS.txt
            done
            echo ${line} >> tmp_TS_Data.txt
            PS_Select=$((PS_Select+1))
            unset line
            if [ "${Plot_single_PS}" == "true" ];then
                gmt psxy -R -J -S${psxy_Size} -Ccategorical.cpt -O -K tmp_TS.txt >> ${Output_File}
            fi
        fi
    done
    echo -e "\e[1;31mTotal ${PS_Select} PS selected.\e[0m"
    # 繪製平均曲線與誤差
    MeanArray=(`gmt math -Ca -S tmp_TS_Data.txt MEAN =`)
    StdArray=(`gmt math -Ca -S tmp_TS_Data.txt STD =`)
    echo "> -Z0" >> tmp_TS_Mean_Error.txt
    echo "Drawing mean time series...."
    for (( j=0; j<${Date_Count}; j=j+1 ))
    do
        echo ${DateArray[${j}]} ${MeanArray[${j}]} ${StdArray[${j}]} >> tmp_TS_Mean_Error.txt
    done
    if [ "${Plot_Mean_PS_W}" == "true" ];then
        gmt psxy -R -J ${psxy_W} -O -K tmp_TS_Mean_Error.txt >> ${Output_File}
    fi
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
        setting_default_xy_plot
        help_config
        if [ "${1}" ];then
            define_io ${1}
            read_edge_time_GPS
            read_edge_y ${1} f 7 50 fix
        else
            define_io
        fi
        config_gereral
        config_io
        config_psbasemap
        config_gps_timeseries
        config_title GPS Time Series Plot
        exit 1
    fi
    
    read_config
    define_argument
    GPS_Name=`echo ${Input_Data} | awk -F. '{printf("%s\n",$1)}'`
    GPS_Lon=`sed -n 1p ${Input_Data} | awk '{printf("%.4f\n",$3)}'`
    GPS_Lat=`sed -n 1p ${Input_Data} | awk '{printf("%.4f\n",$2)}'`
    define_output ${GPS_Name}
    define_edge_time_GPS

    # 繪製原始資料
    gmt gmtset FORMAT_DATE_IN yyyy-mm-dd PS_MEDIA A3 PS_PAGE_ORIENTATION portrait
    gmt psbasemap -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -J${psbasemap_J} -K -Bsx${Map_Bax}Y -Bpxa0Of${Map_Bbx}o+l"Time" -Bpya${Map_Bay}f${Map_Bby}+l"Height (mm)" -BWSen -X1.5i -Y1.5i > ${Output_File}
    awk '{print $1, $7}' ${Input_Data} | gmt psxy -J -R${First_YearDate}/${Last_YearDate}/${Edge_Lower}/${Edge_Upper} -S${psxy_Size} -G${psxy_HG} -K -O -V >> ${Output_File}

    gmt psbasemap -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -J -O -K -Bsx${Map_Bax}Y -Bpxa0Of${Map_Bbx}o -Bpya${Map_Bay}f${Map_Bby}+l"Longitude (mm)" -BWSen -Y5i >> ${Output_File}
    awk '{print $1, $6}' ${Input_Data} | gmt psxy -J -R${First_YearDate}/${Last_YearDate}/${Edge_Lower}/${Edge_Upper} -S${psxy_Size} -G${psxy_LatG} -K -O -V >> ${Output_File}

    gmt psbasemap -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -J -O -K -Bsx${Map_Bax}Y -Bpxa0Of${Map_Bbx}o -Bpya${Map_Bay}f${Map_Bby}+l"Latitude (mm)" -BWSen+t"${Title}" -Y5i >> ${Output_File}
    awk '{print $1, $5}' ${Input_Data} | gmt psxy -J -R${First_YearDate}/${Last_YearDate}/${Edge_Lower}/${Edge_Upper} -S${psxy_Size} -G${psxy_LonG} -K -O -V >> ${Output_File}

    echo "75 96 GPS Station : ${GPS_Name}" | gmt pstext -R0/100/0/100 -J -F+f16p+jTL -O -K >> ${Output_File}
    echo "75 90 Lat : ${GPS_Lon}" | gmt pstext -R -J -F+f16p+jTL -O -K >> ${Output_File}
    echo "75 84 Lon : ${GPS_Lat}" | gmt pstext -R -J -F+f16p+jTL -O -K >> ${Output_File}
    gmt psxy -R -J -T -O >> ${Output_File}
    convert_fig
}

function plot_gps_los(){
    if [ ! -f "${config}" ];then
        setting_default_xy_plot
        help_config
        if [ -n "${1}" ];then
            define_io ${1}
            read_edge_time_GPS
            read_edge_y ${1} f 2 50 fix
        else
            define_io
        fi
        config_gereral
        config_io
        config_psbasemap
        config_gps_timeseries
        config_title GPS Time Series Plot
        exit 1
    fi

    read_config
    define_argument
    define_xy_offset 3 4
    define_output ${Input_Data}
    define_edge_time_GPS

    if [ ${StartDate} ];then
        StartYear=`echo ${StartDate} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$1)}'`
        StartDay=`echo ${StartDate} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$2)}'`
        StartYearDay=`gmt math -Q ${StartDay} 365 DIV =`
        Start_YearDate=`gmt math -Q ${StartYearDay} ${StartYear} ADD =`
        LOS_Offset=`cat ${Input_Data} | awk '{printf("%.8f %.8f\n",$1,$2)}' | grep ${Start_YearDate} | awk '{print $2}'`
        if [ -z ${LOS_Offset} ];then
            Date_Offset=`gmt math -C0 ${Input_Data} ${Start_YearDate} SUB ABS = | gmt info -C -o0`
            Start_YearDate=`gmt math -Q ${Start_YearDate} ${Date_Offset} SUB =`
            LOS_Offset=`cat ${Input_Data} | awk '{printf("%.8f %.8f\n",$1,$2)}' | grep ${Start_YearDate} | awk '{print $2}'`
        fi
        if [ -z ${LOS_Offset} ];then
            Start_YearDate=`gmt math -Q ${Start_YearDate} ${Date_Offset} ADD =`
            LOS_Offset=`cat ${Input_Data} | awk '{printf("%.8f %.8f\n",$1,$2)}' | grep ${Start_YearDate} | awk '{print $2}'`
        fi
    fi
	if [ -z ${LOS_Offset} ];then
		LOS_Offset=0	
	fi
    gmt psbasemap -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -J${psbasemap_J} -BWSen+t"${Title}" -Bsx${Map_Bax}Y -Bpxa${Map_Bbx}Of1o+l"Time" -By${psbasemap_By}+l"LOS Displacement (mm)" -K -V ${X} ${Y} > ${Output_File}
    awk '{print $1, $2-('${LOS_Offset}')}' ${Input_Data} | gmt psxy -J -R${First_YearDate}/${Last_YearDate}/${Edge_Lower}/${Edge_Upper} -S${psxy_Size} -G${psxy_HG} -K -O -V >> ${Output_File}

    gmt psxy -R -J -T -O >> ${Output_File}
    convert_fig
}

function plot_image(){
    if [ ! -f "${config}" ];then
        define_io
        read_edge_x ${Input_LonLat} f 1 0.1
        read_edge_y ${Input_LonLat} f 2 0.1
        setting_default_map_plot

        help_config
        config_gereral
        config_io
        config_psbasemap
        config_basemap_image
        config_addition_layer
        config_title
        exit 1
    fi

    read_config
    define_argument
    define_xy_offset 3 4
    define_output

    gmt psbasemap -J${psbasemap_J} -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -BWSen+t"${Title}" -Bx${psbasemap_Bx} -By${psbasemap_By} ${X} ${Y} -K -P -V > ${Output_File}

    crop_image ${Edge_Left} ${Edge_Upper} ${Edge_Right} ${Edge_Lower}
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
    if [ ! -f "${config}" ];then
        read_edge_x_time ${Input_Date} 1
        read_edge_y ${Input_Bperp} f 1 50
        define_io
        echo "Please setup ${config} for input."
        echo
        echo "# Configure for gmt_plot, please visit GMT website for more detail." > ${config}
        setting_default_xy_plot
        config_gereral
        config_io
        config_psbasemap
        config_psxy_baseline
        config_title Baseline Plot
        exit 1
    fi
    read_config
    define_argument
    define_xy_offset 3 3
    define_output
    Imgs_Count=`wc -l ${Input_Date} | awk '{print $1}'`
    BperpArray=(`cat ${Input_Bperp} | awk '{printf("%d\n",$1)}'`)
    DateArray=(`cat ${Input_Date} | awk '{printf("%d\n",$1)}' | gmt gmtconvert -fT`)
    
    gmt gmtset FORMAT_DATE_IN yyyy-mm-dd
    gmt psbasemap -J${psbasemap_J} -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -BWSen+t"${Title}" -Bsx${Map_Bax}Y -Bpxa${Map_Bbx}Of1o+l"Time" -By${psbasemap_By}+l"Bperp (m)" ${X} ${Y} -K -V > ${Output_File}
    cp ${Output_File} temp.ps
    rm ${Output_File}

    echo "DInSAR"
    define_output dinsar
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
        define_output sbas
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

function plot_profile(){
    if [ ! -f "${config}" ];then
        read_edge_x
        read_edge_y
        define_io ps_mean_v.xy
        setting_default_xy_plot
        help_config
        config_gereral
        config_io
        config_psbasemap
        config_basemap_image
        config_addition_layer
        config_psxy_profile
        config_title LOS Velocity Profile
        exit 1
    fi

    read_config
    define_argument
    define_xy_offset 3 4
    define_output
    if [ "${StartLon}" ] && [ "${StartLat}" ] && [ "${EndLon}" ] && [ "${EndLat}" ];then
        echo "${StartLon} ${StartLat}" > tmp_profile.txt
        echo "${EndLon} ${EndLat}" >> tmp_profile.txt
        unset StartLon
        unset StartLat
        unset EndLon
        unset EndLat
    fi
    if [ -z "${Addition_Layers}" ] && [ -f "tmp_profile.txt" ];then
        Addition_Layers=tmp_profile.txt
    elif [ -z "${Addition_Layers}" ] && [ ! -f "tmp_profile.txt" ];then
        echo "No input profile."
        exit 1
    else
        Addition_Layers="${Addition_Layers} tmp_profile.txt"
    fi

    gmt psbasemap -J${psbasemap_J} -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -BSen+t"${Title}" -Bx${psbasemap_Bx}+l"Distence (m)" ${X} ${Y} -K > ${Output_File}
    project_layer
    
    # echo "Project DEM into tmp_topo_profile.gmt"
    # gmt project -C${start} -E${end} -G0.005 -Q > tmp_profile.gmt
    # if [ `gmt math -Q ${StartLon} ${EndLon} GT =` -eq 1 ];then
    #     win_start_x=${EndLon}
    #     win_end_x=${StartLon}
    # else
    #     win_start_x=${StartLon}
    #     win_end_x=${EndLon}
    # fi
    # if [ `gmt math -Q ${StartLat} ${EndLat} GT =` -eq 1 ];then
    #     win_start_y=${EndLat}
    #     win_end_y=${StartLat}
    # else
    #     win_start_y=${StartLat}
    #     win_end_y=${EndLat}
    # fi
    # crop_image ${win_start_x} ${win_end_y} ${win_end_x} ${win_start_y}
    # gmt grdtrack tmp_profile.gmt -G${Basemap_Output} > tmp_topo_profile.gmt
    
    
    # gmt psxy tmp_topo_profile.gmt -i2,3 -R -J -BE -By${psbasemap_By}+l"Elevation (km)" -O -K >> ${Output_File}
    

    # 封檔
    gmt psxy -R -J -T -O >> ${Output_File}
    convert_fig
    #刪除暫存檔
    rm tmp_*
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

if [ -f "gmt.conf" ];then
    rm gmt.conf
fi

define_configure

if [ "${mode}" == "velocity" ];then
    echo "Start to plot PSI velocity...."
    plot_velocity
elif [ "${mode}" == "deformation" ];then
    echo "Start to plot PSI deformation...."
    plot_deformation
elif [ "${mode}" == "timeseries" ];then
    if [ -f "${3}" ];then
        LonLat_list=`cat ${3}`
        for LonLat in ${LonLat_list}
        do
            PS_Center_Lon=`echo ${LonLat} | awk 'BEGIN {FS = ","} {print $1}'`
            PS_Center_Lat=`echo ${LonLat} | awk 'BEGIN {FS = ","} {print $2}'`
            echo "Batch processing for time series...."
            echo "Plotting PS ${PS_Center_Lon} ${PS_Center_Lat}"
            plot_timeseries ${PS_Center_Lon} ${PS_Center_Lat}
        done
    else
        echo "Start to plot PSI time series...."
        plot_timeseries
    fi
elif [ "${mode}" == "baseline" ];then
    echo "Start to plot interferogram baseline...."
    plot_baseline
elif [ "${mode}" == "gps" ];then
    if [ -n "${3}" ];then
        echo "Start to plot GPS time series for file: ${3}...."
        plot_gps ${3}
    else
        echo "Start to plot GPS time series...."
        plot_gps
    fi
elif [ "${mode}" == "gpslos" ];then
    if [ -n "${3}" ];then
        echo "Start to plot LOS time series for GPS file: ${3}...."
        plot_gps_los ${3}
    else
        echo "Start to plot GPS time series for GPS...."
        plot_gps_los
    fi
elif [ "${mode}" == "image" ];then
    echo "Start to plot image...."
    plot_image
elif [ "${mode}" == "profile" ];then
    echo "Start to plot profile...."
    plot_profile
else
    help
fi

end=$(date +%s.%N)
runtime=$(echo "${end} - ${start}" | bc)
echo "Runtime was ${runtime}"
