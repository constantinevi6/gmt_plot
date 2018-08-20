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

function define_configure(){
    if [ -z "${Input_config}" ];then
        config=gmt_plot_${mode}.config
    else
        config=${Input_config}
    fi
}

function config_gereral(){
    echo "# Configure for gmt_plot, please visit GMT website for more detail." > ${config}
    echo "# General setting" >> ${config}
    echo "## FORMAT_GEO_MAP 地圖邊框座標格式" >> ${config}
    echo "## MAP_FRAME_TYPE 地圖邊框形式，plain=細框，fancy=斑馬紋粗框" >> ${config}
    echo "## FONT_ANNOT_PRIMARY 坐標軸字體設定" >> ${config}
    echo "gmt_config=\"" >> ${config}
    if [ "${mode}" == "v" ];then
        echo "FORMAT_GEO_MAP=ddd.xxF" >> ${config}
        echo "MAP_FRAME_TYPE=fancy" >> ${config}
        echo "MAP_FRAME_PEN=thicker" >> ${config}
        echo "FONT=Times-Roman" >> ${config}
        echo "FONT_LOGO=Times-Roman" >> ${config}
        echo "FONT_TITLE=24p,Times-Roman" >> ${config}
        echo "FONT_ANNOT_PRIMARY=12p,Times-Roman" >> ${config}
    elif [ "${mode}" == "d" ];then
        echo "FORMAT_GEO_MAP=ddd.xxF" >> ${config}
        echo "MAP_FRAME_TYPE=plain" >> ${config}
        echo "MAP_FRAME_PEN=thicker" >> ${config}
        echo "FONT=Times-Roman" >> ${config}
        echo "FONT_LOGO=Times-Roman" >> ${config}
        echo "FONT_ANNOT_PRIMARY=6p,Times-Roman" >> ${config}
    elif [ "${mode}" == "ts" ];then
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
    elif [ "${mode}" == "bl" ];then
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

function config_basemap(){
    echo "# Basemap setting" >> ${config}
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

function config_image(){
    echo "# Image setting" >> ${config}
    echo "## 是否繪製底圖" >> ${config}
    echo "Plot_Image=false" >> ${config}
    echo "## 輸入底圖的絕對路徑" >> ${config}
    echo "Image=" >> ${config}
    echo "## 底圖類型，DEM=數值地形模型，IFG=差分干涉圖，IMG=多光譜影像" >> ${config}
    echo "Image_Type=DEM" >> ${config}
    echo "## 輸出底圖名稱" >> ${config}
    echo "Image_Output=image_crop" >> ${config}
    echo "## 是否重新計算DEM陰影" >> ${config}
    echo "Image_Make_Shade=true" >> ${config}
    echo "## 設定DEM/IFG色帶樣式，gray=灰階，jet=彩虹" >> ${config}
    echo "Image_makecpt_color=" >> ${config}
    echo "## 設定DEM/IFG色帶，格式=[最小值]/[最大值]/[變色間隔]" >> ${config}
    echo "Image_makecpt=-1000/1000/1" >> ${config}
}

function config_psxy(){
    echo "# psxy setting" >> ${config}
    echo "## 設定資料點樣式與大小，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
    echo "psxy_Size=0.02" >> ${config}
    echo "psxy_Type=c" >> ${config}
    echo "psxy_G=black" >> ${config}
    echo "## 設定Colorbar，格式=[最小值]/[最大值]/[變色間隔]" >> ${config}
    echo "psxy_makecpt=${min_cpt}/${max_cpt}/1" >> ${config}
    echo "psxy_makecpt_color=jet" >> ${config}
    echo "" >> ${config}
}

function config_psxy_baseline(){
    echo "# psxy setting" >> ${config}
    echo "## 設定資料點樣式與大小，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
    echo "psxy_Size=0.02" >> ${config}
    echo "psxy_Type=c" >> ${config}
    echo "psxy_G=black" >> ${config}
    echo "## 設定主影像資料點樣式與大小" >> ${config}
    echo "M_psxy_Size=c0.4" >> ${config}
    echo "M_psxy_G=red" >> ${config}
    echo "## 設定連線樣式" >> ${config}
    echo "psxy_W=2p,gray" >> ${config}
    echo "" >> ${config}
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
    echo "Addition_Layers=\"" >> ${config}
    echo "\"" >> ${config}
    echo "## 設定點樣式與大小，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
    echo "Layer_Point_Size=" >> ${config}
    echo "Layer_Point_Color=" >> ${config}
    echo "## 設定線寬度與顏色" >> ${config}
    echo "Layer_Line_Size=" >> ${config}
    echo "Layer_Line_Color=" >> ${config}
    echo "## 設定多邊形樣式" >> ${config}
    echo "## 設定多邊形邊線寬與顏色" >> ${config}
    echo "Layer_Polygon_Line_Size=" >> ${config}
    echo "Layer_Polygon_Line_Color=" >> ${config}
    echo "## 設定多邊形填充顏色" >> ${config}
    echo "Layer_Polygon_Color=" >> ${config}
    echo "" >> ${config}
}

function config_title(){
    echo "# title setting" >> ${config}
    echo "Title=\"\"" >> ${config}
}

function config_default_v(){
    Map_Projection=M
    Map_Width=6
    Map_Offset_X=4
    scale_Label="LOS Velocity (mm/yr)"
}

function config_default_ts(){
    Map_Projection=X
    Map_Width=9
    Map_High=6
    Map_Bax=10
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
    psbasemap_Bx=a${Map_Bax}b${Map_Bbx}
    psbasemap_By=a${Map_Bay}b${Map_Bby}
    if [ "${Map_Offset_X}" != "" ];then
        X=-X${Map_Offset_X}
    fi
    if [ "${Map_Offset_Y}" != "" ];then
        Y=-Y${Map_Offset_Y}
    fi
    psxy_S=${psxy_Type}${psxy_Size}
    scale_B=a${scale_Ba}f${scale_Bf}
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
    Edge_Lower=`cat ${Input_Y} | awk '{printf("%d\n",$1)}' | gmt info -I1 -C | cut -f1`
    Edge_Upper=`cat ${Input_Y} | awk '{printf("%d\n",$1)}' | gmt info -I1 -C | cut -f2`
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
}

function crop_image(){
    Image_Output=${Image_Output}_${Image_Type}.tif
    if [ -f "${Image_Output}" ];then
        basemap_crop_xmin=`grdinfo ${Image_Output} | grep 'x_min' | awk '{print $3}'`
        basemap_crop_xmax=`grdinfo ${Image_Output} | grep 'x_min' | awk '{print $5}'`
        basemap_crop_ymin=`grdinfo ${Image_Output} | grep 'y_min' | awk '{print $3}'`
        basemap_crop_ymax=`grdinfo ${Image_Output} | grep 'y_min' | awk '{print $5}'`
        First_Lon_Sub=`gmt math -Q ${Edge_Left} ${basemap_crop_xmin} SUB ABS 0.001 GT =`
        Last_Lon_Sub=`gmt math -Q ${Edge_Right} ${basemap_crop_xmax} SUB ABS 0.001 GT =`
        Lower_Lat_Sub=`gmt math -Q ${Edge_Lower} ${basemap_crop_ymin} SUB ABS 0.001 GT =`
        Upper_Lat_Sub=`gmt math -Q ${Edge_Upper} ${basemap_crop_ymax} SUB ABS 0.001 GT =`
        if [ "${First_Lon_Sub}" -eq 1 ] || [ "${Last_Lon_Sub}" -eq 1 ] ||[ "${Lower_Lat_Sub}" -eq 1 ] ||[ "${Upper_Lat_Sub}" -eq 1 ];then
            gdal_translate -projwin ${Edge_Left} ${Edge_Upper} ${Edge_Right} ${Edge_Lower} -of GTiff ${Image} ${Image_Output}
        fi
    else
        gdal_translate -projwin ${Edge_Left} ${Edge_Upper} ${Edge_Right} ${Edge_Lower} -of GTiff ${Image} ${Image_Output}
    fi
}

function plot_image(){
    if [ "${Image_Type}" == "DEM" ];then
        # 計算DEM陰影
        #if [ "${Make_Shade}" == "true" ] || [ ! -f "shade.grd" ];then
		#	echo ${Make_Shade}
        #    gmt grdgradient ${Image_Output} -Gshade.grd -A0 -Ne0.6 -V
        #    sed -i 's/Make_Shade=true/Make_Shade=false/g' ${config}
        #fi
        # 將DEM底圖加上灰階
        gmt grdgradient ${Image_Output} -Gshade.grd -A0 -Ne0.6 -V
        gmt makecpt -C${Image_makecpt_color} -T${Image_makecpt} -Z > image_cpt.cpt
        gmt grdimage ${Image_Output} -Cimage_cpt.cpt -Ishade.grd -J -R -K -O -P -V >> ${Output_File}
    elif [ "${Image_Type}" == "IFG" ];then
        gmt makecpt -C${Image_makecpt_color} -T${Image_makecpt} -Z > image_cpt.cpt
        gmt grdimage ${Image_Output} -Cimage_cpt.cpt -J -R -K -O -P -V >> ${Output_File}
    elif [ "${Image_Type}" == "IMG" ];then
        gmt grdimage ${Image_Output}+b0 ${Image_Output}+b1 ${Image_Output}+b2 -J -R -E300 -K -O -P -V >> ${Output_File}
    fi
}

function plot_ps(){
    gmt makecpt -C${psxy_makecpt_color} -T${psxy_makecpt} -Z > ps.cpt
    gmt psxy ${Input_Data} -J -R -S${psxy_S} -Cps.cpt -K -O -V >> ${Output_File}
}

function plot_coastline(){
    gmt pscoast -J -R -B -Df -S140/206/250 -W2/0 -V -K -O >> ${Output_File}
}

function plot_legend(){
    gmt psscale -Cps.cpt -J -R -DjBC+w10c/0.5c+jTC+h+o0/1c -B${scale_B}+l"${scale_Label}" -K -O -P -V >> ${Output_File}
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
    psconvert ${psconvert_T} ${psconvert_A} -P ${Output_File}
}

function plot_v(){
    # 產生Configure
    if [ ! -f "${config}" ];then
        define_edge_geo
        define_edge_cpt
        config_default_v

        help_config
        config_gereral
        config_io
        config_basemap
        config_image
        config_psxy
        config_scale
        config_title
        exit 1
    fi

    # 載入參數
    setting_config
    setting_argument
    setting_output
    # 底圖設定
    gmt psbasemap -J${psbasemap_J} -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -BWSen+t"${Title}" -Bx${psbasemap_Bx} -By${psbasemap_By} ${X} ${Y} -K -P -V > ${Output_File}

    if [ "${Plot_Image}" == "true" ];then
        crop_image
        plot_image
    else
        echo Skipping plot image.
    fi
    plot_ps
    plot_coastline
    plot_legend

    # 封檔
    gmt psxy -R -J -T -O >> ${Output_File}
    convert_fig
}

function plot_d(){

    if [ ! -f "${config}" ];then
        define_edge_geo
        define_edge_cpt
        config_default_v

        help_config
        config_gereral
        config_io
        config_basemap
        config_image
        config_psxy
        config_scale
        config_title
        exit 1
    fi
    source ${pwd}/${config}
    Output_File=${Output_File}.ps
}

function plot_ts(){
    if [ ! -f "${config}" ];then
        config_default_ts
        help_config
        config_gereral
        config_io
        config_basemap
        config_image
        config_psxy
        config_scale
        config_title
        exit 1
    fi
    source ${pwd}/${config}
    Output_File=${Output_File}.ps
}

function plot_bl(){
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
        config_basemap
        config_psxy_baseline
        exit 1
    fi
    setting_config
    setting_argument
    setting_output
    Imgs_Count=`wc -l ${Input_Date} | awk '{print $1}'`
    BperpArray=(`cat ${Input_Bperp} | awk '{printf("%d\n",$1)}'`)
    DateArray=(`cat ${Input_Date} | awk '{printf("%d\n",$1)}' | gmt gmtconvert -fT`)
    
    gmt gmtset FORMAT_DATE_IN yyyy-mm-dd
    gmt psbasemap -J${psbasemap_J} -R${Edge_Left}/${Edge_Right}/${Edge_Lower}/${Edge_Upper} -BWSen+t"${Title}" -Bsx1Y -Bpxa3Of1o -Bpy200 ${X} ${Y} -K -V > ${Output_File}
    cp ${Output_File} temp.ps

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
        echo ${DateArray[${i}]} ${BperpArray[${i}]} | gmt psxy -R -J -Fr${Master}/0 -W${psxy_W} -O -K >> ${Output_File}
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
            echo ${SlaveDate} ${SlaveBperp} | gmt psxy -R -J -Fr${MasterDate}/${MasterBperp} -W${psxy_W} -O -K >> ${Output_File}
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
if [ "${mode}" == "v" ];then
    plot_v
elif [ "${mode}" == "d" ];then
    plot_d
elif [ "${mode}" == "ts" ];then
    plot_ts
elif [ "${mode}" == "bl" ];then
    plot_bl
fi