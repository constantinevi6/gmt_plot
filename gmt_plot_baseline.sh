#!/bin/bash
# 將影像對用GMT做成圖
#
# 2017/12/27 CV 初版
# 2018/01/26 CV Feature:重新設計迴圈，點線分開繪圖，加入座標軸名稱。
# 2018/04/02 CV Feature:增加參數用以載入特定的設定檔
#

# 搜尋影像日期檔
if [ -f "date.txt" ];then
    Input_Data_date=date.txt
else
    echo "Can't find date.txt."
fi

# 搜尋基線長檔
if [ -f "bperp.txt" ];then
    Input_Data_Bperp=bperp.txt
else
    echo "Can't find bperp.txt."
fi

# 計算底圖範圍
gmt gmtset FORMAT_DATE_IN yyyymmdd FORMAT_DATE_OUT yyyy-mm-dd
First_Date=`cat ${Input_Data_date} | awk '{printf("%d\n",$1)}' | gmt info -fT -I1 -C | cut -f1`
Last_Date=`cat ${Input_Data_date} | awk '{printf("%d\n",$1)}' | gmt info -fT -I1 -C | cut -f2`
Lower_Bperp=`cat ${Input_Data_Bperp} | awk '{printf("%d\n",$1)}' | gmt info -I1 -C | cut -f1`
Upper_Bperp=`cat ${Input_Data_Bperp} | awk '{printf("%d\n",$1)}' | gmt info -I1 -C | cut -f2`

# Configure
if [ -z "${1}" ];then
config=gmt_plot_baseline.config
else
config=${1}
fi

if [ ! -f "${config}" ];then
echo "Please setup ${config} for input."
echo "Usage: ${0} [Input Config File]"
echo "       If [Input Config File] is not select,  gmt_plot_baseline.config will be used as the defult config file"
echo
echo "# Configure for gmt_plot_baseline, please visit GMT website for more detail." >> ${config}

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
echo "\"" >> ${config}
echo "## 輸入與輸出" >> ${config}
echo "Input_Data_date=${Input_Data_date}" >> ${config}
echo "Input_Data_Bperp=${Input_Data_Bperp}" >> ${config}
echo "Output_File_Name=GMT_Baseline_plot.ps" >> ${config}
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
echo "Upper_Bperp=$((${Upper_Bperp}+20))" >> ${config}
echo "Lower_Bperp=$((${Lower_Bperp}-20))" >> ${config}
echo "## 設定座標軸" >> ${config}
echo "## 設定年座標名稱顯示間隔" >> ${config}
echo "YearAxis=1" >> ${config}
echo "## 設定月座標名稱顯示間隔" >> ${config}
echo "MonthAxis=1" >> ${config}
echo "## 設定月座標刻度間隔" >> ${config}
echo "mAxis=1" >> ${config}
echo "## 設定縱座標刻度間隔" >> ${config}
echo "BperpAxis=20" >> ${config}
echo "" >> ${config}
echo "# Plot setting" >> ${config}
echo "## 設定連線樣式" >> ${config}
echo "psxy_W=2p,gray" >> ${config}
echo "## 設定資料點樣式與大小，格式=[樣式代號][大小]，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
echo "psxy_Size=c0.2" >> ${config}
echo "psxy_G=black" >> ${config}
echo "## 設定主影像資料點樣式與大小" >> ${config}
echo "M_psxy_Size=c0.4" >> ${config}
echo "M_psxy_G=red" >> ${config}

exit 1
fi

# 當前目錄
pwd=`pwd`

# 讀取設定檔
source ${pwd}/${config}

# GMT廣域設定
gmt gmtset ${gmt_config}

# 載入數據
Dates=`cat ${Input_Data_date} | awk '{printf("%d\n",$1)}' | gmt gmtconvert -fT`
Bperps=`cat ${Input_Data_Bperp} | awk '{printf("%d\n",$1)}'`
DateArray=(`cat ${Input_Data_date} | awk '{printf("%d\n",$1)}' | gmt gmtconvert -fT`)
BperpArray=(`cat ${Input_Data_Bperp} | awk '{printf("%d\n",$1)}'`)
Date_Count=`wc -l ${Input_Data_date} | awk '{print $1}'`

# 搜尋主影像
for (( i=0; i<${Date_Count}; i=i+1 ))
do
    if [ "${BperpArray[${i}]}" -eq 0 ];then
        master=${DateArray[${i}]}
        echo "Master image is ${master}."
    fi
done

# 繪圖
gmt gmtset FORMAT_DATE_IN yyyy-mm-dd
gmt psbasemap -R${First_Date}/${Last_Date}/${Lower_Bperp}/${Upper_Bperp} -JX9i/6i -K -Bsx${YearAxis}Y -Bpxa${MonthAxis}Of${mAxis}o+l"Time" -Bpy${BperpAxis}+l"Bperp (m)" -BWSen+t"Baseline Plot" > ${Output_File_Name}
for (( i=0; i<${Date_Count}; i=i+1 ))
do
    echo ${DateArray[${i}]} ${BperpArray[${i}]} | gmt psxy -R -J -Fr${master}/0 -W${psxy_W} -O -K >> ${Output_File_Name}
done
for (( i=0; i<${Date_Count}; i=i+1 ))
do
    if [ "${DateArray[${i}]}" == "${master}" ];then
        echo ${DateArray[${i}]} ${BperpArray[${i}]} | gmt psxy -R -J -S${M_psxy_Size} -G${M_psxy_G} -O -K >> ${Output_File_Name}
    else
        echo ${DateArray[${i}]} ${BperpArray[${i}]} | gmt psxy -R -J -S${psxy_Size} -G${psxy_G} -O -K >> ${Output_File_Name}
    fi
done

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
