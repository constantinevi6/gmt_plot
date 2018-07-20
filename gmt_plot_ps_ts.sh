#!/bin/bash
# 繪製PS點Time Series
#
# 2017/12/27 CV 初版
# 2018/04/02 CV Feature:增加參數用以載入特定的設定檔
# 2018/06/07 CV Feature:紀錄中心座標與取點數量，輸出取點座標檔
# 2018/06/08 CV Fix:修正標題文字錯誤，修正重做時座標檔未重寫的錯誤
# 2018/06/20 CV Feature:增加轉檔功能
#

# 搜尋影像日期檔
if [ -f "date.txt" ];then
    Input_Data_date=date.txt
else
    echo "Can't find date.txt."
fi

# 計算底圖範圍
gmt gmtset FORMAT_DATE_IN yyyymmdd FORMAT_DATE_OUT yyyy-mm-dd
First_Date=`cat ${Input_Data_date} | awk '{printf("%d\n",$1)}' | gmt info -fT -I1 -C | cut -f1`
Last_Date=`cat ${Input_Data_date} | awk '{printf("%d\n",$1)}' | gmt info -fT -I1 -C | cut -f2`

# Configure
if [ -z "${1}" ];then
config=gmt_plot_ps_ts.config
else
config=${1}
fi

if [ ! -f "${config}" ];then
echo "Please setup ${config} for input."
echo
echo "# Configure for gmt_plot_ps_ts, please visit GMT website for more detail." >> ${config}

echo "# General setting" >> ${config}
echo "gmt_config=\"" >> ${config}
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
echo "\"" >> ${config}
echo "## 輸入選項" >> ${config}
echo "Input_Data_date=${Input_Data_date}" >> ${config}
echo "Input_Data_lonlat=ps_ll.txt" >> ${config}
echo "Input_Data=ps_u-dm.*.xy" >> ${config}
echo "## 輸出選項" >> ${config}
echo "Output_File=GMT_PS" >> ${config}
echo "## 輸出圖檔格式，支援JPG、PNG、PDF、TIFF、BMP、EPS、PPM、SVG" >> ${config}
echo "Output_Figure_Format=PNG" >> ${config}
echo "## 自動裁切空白的部分" >> ${config}
echo "Output_Figure_Adjust=true" >> ${config}
echo "## PNG圖檔背景是否為透明" >> ${config}
echo "Output_Figure_Transparent=true" >> ${config}
echo "" >> ${config}
echo "# Basemap setting" >> ${config}
echo "## 設定底圖範圍" >> ${config}
echo "First_Date=${First_Date}" >> ${config}
echo "Last_Date=${Last_Date}" >> ${config}
echo "Upper_D=" >> ${config}
echo "Lower_D=" >> ${config}
echo "## 設定座標軸" >> ${config}
echo "## 設定年座標名稱顯示間隔" >> ${config}
echo "YearAxis=1" >> ${config}
echo "## 設定月座標名稱顯示間隔" >> ${config}
echo "MonthAxis=1" >> ${config}
echo "## 設定月座標刻度間隔" >> ${config}
echo "mAxis=1" >> ${config}
echo "## 設定縱座標刻度間隔" >> ${config}
echo "DAxis=10" >> ${config}
echo "" >> ${config}
echo "# Plot setting" >> ${config}
echo "## 設定連線樣式" >> ${config}
echo "psxy_W=1p" >> ${config}
echo "## 設定資料點樣式與大小，格式=[樣式代號][大小]，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
echo "psxy_Size=c0.1" >> ${config}
echo "psxy_Size_Mean=c0.2" >> ${config}
echo "psxy_G=black" >> ${config}
echo "## 設定PS中心座標與範圍，範圍單位:度" >> ${config}
echo "PS_Center_Lon=" >> ${config}
echo "PS_Center_Lat=" >> ${config}
echo "PS_Radius=0.001" >> ${config}

exit 1
fi

# 當前目錄
pwd=`pwd`

# 讀取設定檔
source ${pwd}/${config}
Output_File_Name=${Output_File}_${PS_Center_Lon}_${PS_Center_Lat}.ps

# 讀取參數
Input_FilesArray=(`ls -v ${Input_Data}`)

# GMT廣域設定
gmt gmtset ${gmt_config}

# 計算選取範圍
F_Lon=`echo "${PS_Center_Lon}-${PS_Radius}" | bc`
L_Lon=`echo "${PS_Center_Lon}+${PS_Radius}" | bc`
U_Lat=`echo "${PS_Center_Lat}+${PS_Radius}" | bc`
L_Lat=`echo "${PS_Center_Lat}-${PS_Radius}" | bc`

# 刪除暫存檔案
if [ -f "PS_Candidates.txt" ];then
     rm PS_Candidates.txt
fi
if [ -f "PS_TS.txt" ];then
     rm PS_TS.txt
fi
if [ -f "PS_TS_Data.txt" ];then
     rm PS_TS_Data.txt
fi
if [ -f "PS_TS_Mean_Error.txt" ];then
     rm PS_TS_Mean_Error.txt
fi
if [ -f "${Output_File}_${PS_Center_Lon}_${PS_Center_Lat}.txt" ];then
     rm ${Output_File}_${PS_Center_Lon}_${PS_Center_Lat}.txt
fi

# 載入數據
nl  ${Input_Data_lonlat} | awk '$2>'"${F_Lon}"' {printf("%d %.8f %.8f\n",$1,$2,$3)}' | awk '$2<'"${L_Lon}"' {printf("%d %.8f %.8f\n",$1,$2,$3)}' | awk '$3<'"${U_Lat}"' {printf("%d %.8f %.8f\n",$1,$2,$3)}' | awk '$3>'"${L_Lat}"' {printf("%d %.8f %.8f\n",$1,$2,$3)}' >> PS_Candidates.txt
Date_Count=`wc -l ${Input_Data_date} | awk '{print $1}'`
PS_Count=`wc -l PS_Candidates.txt | awk '{print $1}'`
LineArray=(`cat PS_Candidates.txt | awk '{printf("%d\n",$1)}'`)
LonArray=(`cat PS_Candidates.txt | awk '{printf("%.8f\n",$2)}'`)
LatArray=(`cat PS_Candidates.txt | awk '{printf("%.8f\n",$3)}'`)
DateArray=(`cat ${Input_Data_date} | awk '{printf("%d\n",$1)}' | gmt gmtconvert -fT`)

# 繪製原始資料
gmt gmtset FORMAT_DATE_IN yyyy-mm-dd
gmt psbasemap -R${First_Date}/${Last_Date}/${Lower_D}/${Upper_D} -JX9i/4i -K -Bsx${YearAxis}Y -Bpxa${MonthAxis}Of${mAxis}o+l"Time" -Bpy${DAxis}+l"Displacement (mm)" -BWSen+t"PS Time Series Plot" -X1.5i -Y1.5i > ${Output_File_Name}
echo "Calculate PS inside selected range...."
for (( i=0; i<${PS_Count}; i=i+1 ))
do
    Lon=${LonArray[${i}]}
    Lat=${LatArray[${i}]}
    Lon_Sub=`gmt math -Q ${Lon} ${PS_Center_Lon} SUB =`
    Lat_Sub=`gmt math -Q ${Lat} ${PS_Center_Lat} SUB =`
    r2=`gmt math -Q ${Lon_Sub} ${Lat_Sub} R2 =`
    R2=`gmt math -Q ${PS_Radius} SQR =`
    Identify=`gmt math -Q ${R2} ${r2} GE =`
    if [ "${Identify}" -eq "1" ];then
        echo "> -Z"${i} >> PS_TS.txt
        echo ${Lon} ${Lat} >> ${Output_File}_${PS_Center_Lon}_${PS_Center_Lat}.txt
        for (( j=0; j<${Date_Count}; j=j+1 ))
        do
            data=`sed -n "${LineArray[${i}]}p" ${Input_FilesArray[${j}]} | awk '{printf("%.8f\n",$3)}'`
            line=${line}\ ${data}
            echo ${DateArray[${j}]} ${data} ${i} >> PS_TS.txt
        done
        echo ${line} >> PS_TS_Data.txt
        unset line
        gmt psxy -R -J -S${psxy_Size} -Ccategorical.cpt -O -K PS_TS.txt >> ${Output_File_Name}
    else
        continue
    fi
done

PS_Select=`wc -l PS_TS_Data.txt | awk '{print $1}'`
echo -e "\e[1;31mTotal ${PS_Select} PS selected.\e[0m"

# 繪製平均曲線與誤差
MeanArray=(`gmt math -Ca -S PS_TS_Data.txt MEAN =`)
StdArray=(`gmt math -Ca -S PS_TS_Data.txt STD =`)
echo "> -Z0" >> PS_TS_Mean_Error.txt
echo "Drawing error bar...."
for (( j=0; j<${Date_Count}; j=j+1 ))
do
    echo ${DateArray[${j}]} ${MeanArray[${j}]} ${StdArray[${j}]} >> PS_TS_Mean_Error.txt
done
gmt psxy -R -J -W${psxy_W} -O -K PS_TS_Mean_Error.txt >> ${Output_File_Name}
gmt psxy -R -J -S${psxy_Size_Mean} -G${psxy_G} -Ey/${psxy_W} -O -K PS_TS_Mean_Error.txt >> ${Output_File_Name}
echo "75 98 Central Lon : ${PS_Center_Lon}" | gmt pstext -R0/100/0/100 -J -F+f16p+jTL -O -K >> ${Output_File_Name}
echo "75 92 Central Lat : ${PS_Center_Lat}" | gmt pstext -R -J -F+f16p+jTL -O -K >> ${Output_File_Name}
echo "75 86 Selected PSs : ${PS_Select}" | gmt pstext -R -J -F+f16p+jTL -O -K >> ${Output_File_Name}
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
