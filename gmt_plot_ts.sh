#!/bin/bash
# 將輸出之PS成果用GMT做成圖
# 這個程式主要用來輸出多圖，適用於PS時間序列 / 各影像之軌道誤差之輸出。
#
# 2017/09/22 CV 初版
# 2018/06/20 CV Feature:增加轉檔功能
#

# 搜尋座標檔
if [ -f "ps_ll.txt" ];then
    Input_Data_lonlat=ps_ll.txt
else
    echo "Can't find ps_ll.txt."
fi

# 計算底圖範圍
First_Lon=`cat ${Input_Data_lonlat} | awk '{printf("%d\n",$1)}' | gmt info -I1 -C | cut -f1`
Last_Lon=`cat ${Input_Data_lonlat} | awk '{printf("%d\n",$1)}' | gmt info -I1 -C | cut -f2`
Upper_Lat=`cat ${Input_Data_lonlat} | awk '{printf("%d\n",$2)}' | gmt info -I1 -C | cut -f2`
Lower_Lat=`cat ${Input_Data_lonlat} | awk '{printf("%d\n",$2)}' | gmt info -I1 -C | cut -f1`

# Configure
config=gmt_plot_ts.config

if [ ! -f "${config}" ];then
echo "Please setup ${config} for input."
echo
echo "# Configure for gmt_plot_ps_ts, please visit GMT website for more detail." >> ${config}

echo "# General setting" >> ${config}
echo "## FORMAT_GEO_MAP 地圖邊框座標格式" >> ${config}
echo "## MAP_FRAME_TYPE 地圖邊框形式，plain=細框，fancy=斑馬紋粗框" >> ${config}
echo "## FONT_ANNOT_PRIMARY 坐標軸字體設定" >> ${config}
echo "gmt_config=\"" >> ${config}
echo "FORMAT_GEO_MAP=ddd.xxF" >> ${config}
echo "MAP_FRAME_TYPE=plain" >> ${config}
echo "MAP_FRAME_PEN=thicker" >> ${config}
echo "FONT=Times-Roman" >> ${config}
echo "FONT_LOGO=Times-Roman" >> ${config}
echo "FONT_ANNOT_PRIMARY=6p,Times-Roman" >> ${config}
echo "\"" >> ${config}
echo "## 輸入選項，Input_Data格式=[PS輸出檔案].*.xy" >> ${config}
echo "Input_Data=ps_u-dm.*.xy" >> ${config}
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
echo "First_Longitude=121E" >> ${config}
echo "Last_Longitude=122E" >> ${config}
echo "Upper_Latitude=25N" >> ${config}
echo "Lower_Latitude=24N" >> ${config}
echo "## 設定每行的圖數" >> ${config}
echo "Columns=4" >> ${config}
echo "## 設定投影方式，M=橫麥卡托投影" >> ${config}
echo "map_projection=M" >> ${config}
echo "## 設定底圖大小" >> ${config}
echo "map_width=3" >> ${config}
echo "## 設定底圖大小單位，c=公分，i=英吋，p=point" >> ${config}
echo "map_width_unit=c" >> ${config}
echo "## 設定底圖之間隔大小" >> ${config}
echo "inter_map_width=1" >> ${config}
echo "inter_map_high=3" >> ${config}
echo "## 設定坐標軸刻度間隔，格式=a[顯示數值之刻度]b[不顯示數值之刻度]" >> ${config}
echo "basemap_Bx=a0.5" >> ${config}
echo "basemap_By=a0.5" >> ${config}
echo "## 是否繪製底圖" >> ${config}
echo "plot_basemap=true" >> ${config}
echo "## 輸入底圖的絕對路徑" >> ${config}
echo "basemap=/data/dem.tif" >> ${config}
echo "## 底圖類型，DEM=數值地形模型，IFG=差分干涉圖，IMG=多光譜影像" >> ${config}
echo "basemap_type=DEM" >> ${config}
echo "## 是否重新計算DEM陰影" >> ${config}
echo "make_shade=true" >> ${config}
echo "## 設定DEM/IFG色帶樣式，gray=灰階，jet=彩虹" >> ${config}
echo "makecpt_C_basemap=gray" >> ${config}
echo "## 設定DEM/IFG色帶，格式=[最小值]/[最大值]/[變色間隔]" >> ${config}
echo "makecpt_T_basemap=-1000/1000/1" >> ${config}
echo "## 第一張底圖位置偏移量" >> ${config}
echo "Offset_X=" >> ${config}
echo "Offset_Y=20" >> ${config}
echo "" >> ${config}

echo "# scale setting" >> ${config}
echo "## 圖例文字說明" >> ${config}
echo "scale_Label=\"Phase (rad)\"" >> ${config}
echo "## 設定圖例坐標軸刻度間隔" >> ${config}
echo "scale_B=a2f1" >> ${config}
echo "## 圖例高度" >> ${config}
echo "scale_height=0.2" >> ${config}
echo "## 圖例坐標軸字體大小" >> ${config}
echo "scale_FONT_ANNOT_PRIMARY=8" >> ${config}
echo "## 圖例文字說明字體大小" >> ${config}
echo "scale_FONT_LABEL=10" >> ${config}
echo "" >> ${config}

echo "# makecpt setting" >> ${config}
echo "## 設定Colorbar大小，格式=[最小值]/[最大值]/[變色間隔]" >> ${config}
echo "makecpt_T_ps=-10/10/1" >> ${config}
echo "" >> ${config}

echo "# psxy setting" >> ${config}
echo "## 設定資料點樣式與大小，格式=[樣式代號][大小]，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
echo "psxy_Size=c0.2" >> ${config}
echo "" >> ${config}

echo "# title setting" >> ${config}
echo "## 標題高度位置偏移量(相對於第一張底圖底部)，預設為底圖高間隔+2公分" >> ${config}
echo "title_Offset_Y=\$((\${inter_map_high}+2))" >> ${config}
echo "Title_FONT_Size=20" >> ${config}
echo "Sub_Title_FONT_Size=16" >> ${config}
echo "Title=\"Sentinel-1 (2015-2017)\"" >> ${config}
echo "Sub_Title=\"North Taiwan 10 Pairs\"" >> ${config}

exit 1
fi

# 當前目錄
pwd=`pwd`

# 讀取設定檔
source ${pwd}/${config}
Output_File_Name=${Output_File}.ps

# 讀取參數
psbasemap_J=${map_projection}${map_width}${map_width_unit}
if [ "${Offset_X}" == "" ];then
    X=-Xr1i
else
    X=-X${Offset_X}
fi
if [ "${Offset_Y}" == "" ];then
    Y=-Yr1i
    else
    ori_Offset_Y=${Offset_Y}
    Y=-Y${Offset_Y}
fi
Input_Files=`ls -v ${Input_Data}`

# GMT廣域設定
gmt gmtset ${gmt_config}

# 時間序列處理
plot_count=0
for Input_File in ${Input_Files}
    do
	    echo -e "\e[1;31mProcessing ${Input_File}\e[0m"
        if [ "${plot_count}" == "0" ];then
            O=""
		    save=">"
        else
            O="-O"
            save=">>"
        fi
        # 搜尋影像日期
        if [ -f "day.1.in" ];then
            DateFile=day.1.in
        elif [ -f "date.txt" ];then
            DateFile=date.txt
        fi
        DateArray=(`cat ${DateFile} | awk '{printf("%d\n",$1)}'`)
        Date=${DateArray[${plot_count}]}

        plot_count=$((${plot_count}+1))
        # 計算排列參數
        if [ $((${plot_count}%${Columns})) == "1" ];then	    
            if [ "${plot_count}" == "1" ];then
                Offset_X=r1i
	        else
		        Offset_X=$((-(${map_width}+${inter_map_width})*(${Columns}-1)))
                Offset_Y=$((-${inter_map_high}))
                Y=-Y${Offset_Y}c
            fi
            B_left=W
            X=-X${Offset_X}
        else
            B_left=w
            Offset_X=$((${map_width}+${inter_map_width}))
            X=-X${Offset_X}c
	        Y=""
        fi
        # 設定座標軸顯示
        if [ $((${plot_count}/${Columns})) == "0" ];then
            B_top=N
        elif [ $((${plot_count}/${Columns})) == "1" ] && [ $((${plot_count}%${Columns})) == "0" ];then
            B_top=N
        else
            B_top=n
        fi
        B=-B${B_top}${B_left}se
        # 底圖設定
        gmt psbasemap -J${psbasemap_J} -R${First_Longitude}/${Last_Longitude}/${Lower_Latitude}/${Upper_Latitude} ${B} -Bx${basemap_Bx} -By${basemap_By} ${X} ${Y} -K ${O} -P -V $save ${Output_File_Name}
        # 繪製底圖
        if [ "${plot_basemap}" == "true" ];then
            if [ "${basemap_type}" == "DEM" ];then
                # 計算DEM陰影
                if [ "${make_shade}" == "true" ] || [ ! -f "shade.grd" ];then
                    gmt grdgradient ${basemap} -Gshade.grd -A0 -Ne0.6 -V
                    sed -i 's/make_shade=true/make_shade=false/g' ${config}
                fi
                # 將DEM底圖加上灰階
                gmt makecpt -C${makecpt_C_basemap} -T${makecpt_T_basemap} -Z > basemap_cpt.cpt
                gmt grdimage ${basemap} -Cbasemap_cpt.cpt -Ishade.grd -J -R -K -O -P -V >> ${Output_File_Name}
            elif [ "${basemap_type}" == "IFG" ];then
                gmt makecpt -C${makecpt_C_basemap} -T${makecpt_T_basemap} -Z > basemap_cpt.cpt
                gmt grdimage ${basemap} -Cbasemap_cpt.cpt -J -R -K -O -P -V >> ${Output_File_Name}
            elif [ "${basemap_type}" == "IMG" ];then
                gmt grdimage ${basemap}+b0 ${basemap}+b1 ${basemap}+b2 -J -R -K -O -P -V >> ${Output_File_Name}
            fi
        fi

        # Plot PS LOS velocity points
        # 將PS繪製至底圖上並加上色彩
        if [ -f "${Input_File}" ];then
            gmt makecpt -Cjet -T${makecpt_T_ps} -Z > ps.cpt
            awk '{print $1, $2, $3}' ${Input_File} | gmt psxy -J -R -S${psxy_Size} -Cps.cpt -K -O -V >> ${Output_File_Name}
            echo ${First_Longitude} ${Upper_Latitude} ${Date} | gmt pstext -R -J -D0.1c/-0.1c -F+f${scale_FONT_LABEL}p,Helvetica-Bold+jTL -K -O -P -N -V >> ${Output_File_Name}
        else
            echo "Can't find ${Input_File}, skip psxy plotting."
        fi
        
        # coastline
        gmt pscoast -J -R -B -Df -S140/206/250 -W2/0 -V -K -O >> ${Output_File_Name}
    done

# Colorbar
plot_count=$((${plot_count}+1))
if [ $((${plot_count}%${Columns})) == "1" ];then
    Offset_X=$((-(${map_width}+${inter_map_width})*(${Columns}-1)))
    Offset_Y=$((-${inter_map_high}))
    Y=-Y${Offset_Y}c
    X=-X${Offset_X}
else
    Offset_X=$((${map_width}+${inter_map_width}))
    X=-X${Offset_X}c
    Y=""
fi
gmt psscale -Cps.cpt -J -R -DjTL+w${map_width}c/${scale_height}c+jTL+h -B${scale_B}+l"${scale_Label}" ${X} ${Y} -K -O -P -V --FONT_ANNOT_PRIMARY=${scale_FONT_ANNOT_PRIMARY}p --FONT_LABEL=${scale_FONT_LABEL}p >> ${Output_File_Name}

# 寫入文字
gmt pstext -R0/1/0/1 -JX1c -F+f${Title_FONT_Size}p,Helvetica-Bold+jTC -Xc -Yf$((${ori_Offset_Y}+${title_Offset_Y}))c -K -O -P -N -V <<!>> ${Output_File_Name}
0 0 ${Title}
!
gmt pstext -JX -R -F+f${Sub_Title_FONT_Size}p,Helvetica-Bold+jMC -Y-1c -O -P -N -V <<!>> ${Output_File_Name}
0 0 ${Sub_Title}
!

# 轉檔
psconvert ${psconvert_T} ${psconvert_A} -P ${Output_File_Name}
