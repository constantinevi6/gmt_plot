#!/bin/bash
# 繪製中研院GPS點資料Time Series
#
# 2018/06/07 CV 初版
#

# Configure
if [ -z "${1}" ];then
config=gmt_plot_gps_ts_los.config
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
echo "## 輸入與輸出" >> ${config}
echo "Input_Data=" >> ${config}
echo "Output_File=GMT_gps_los" >> ${config}
echo "## 輸出圖檔格式，支援JPG、PNG、PDF、TIFF、BMP、EPS、PPM、SVG" >> ${config}
echo "Output_Figure_Format=PNG" >> ${config}
echo "## 自動裁切空白的部分" >> ${config}
echo "Output_Figure_Adjust=true" >> ${config}
echo "## PNG圖檔背景是否為透明" >> ${config}
echo "Output_Figure_Transparent=true" >> ${config}
echo "" >> ${config}
echo "# Basemap setting" >> ${config}
echo "## 設定底圖範圍" >> ${config}
echo "First_Date=" >> ${config}
echo "Last_Date=" >> ${config}
echo "Upper_D=100" >> ${config}
echo "Lower_D=-100" >> ${config}
echo "## 設定座標軸" >> ${config}
echo "## 設定年座標名稱顯示間隔" >> ${config}
echo "YearAxis=1" >> ${config}
echo "## 設定月座標名稱顯示間隔" >> ${config}
echo "MonthAxis=3" >> ${config}
echo "## 設定月座標刻度間隔" >> ${config}
echo "mAxis=1" >> ${config}
echo "## 設定縱座標刻度間隔" >> ${config}
echo "DAxis=a50f10" >> ${config}
echo "" >> ${config}
echo "# Plot setting" >> ${config}
echo "## 設定資料點樣式與大小，格式=[樣式代號][大小]，樣式代號: c=圓形，a=星形，d=菱形，s=正方形" >> ${config}
echo "psxy_Size=c0.1" >> ${config}
echo "psxy_HG=blue" >> ${config}
echo "## 設定起點日期" >> ${config}
echo "StartDate=" >> ${config}

exit 1
fi

# 當前目錄
pwd=`pwd`

# 讀取設定檔
source ${pwd}/${config}
Output_File_Name=${Output_File}_${Input_Data}.ps

# 計算底圖範圍
if [ -z ${First_Date} ] || [ -z ${Last_Date} ];then
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
First_Date=`echo ${FirstYear}-${FirstDay} | gmt info -fT -I1 -C | cut -f1`
Last_Date=`echo ${LastYear}-${LastDay} | gmt info -fT -I1 -C | cut -f1`
else
gmt gmtset FORMAT_DATE_IN yyyy-mm-dd FORMAT_DATE_OUT yyyy-jjj
FirstYear=`echo ${First_Date} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$1)}'`
FirstDay=`echo ${First_Date} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$2)}'`
FirstYearDay=`gmt math -Q ${FirstDay} 365 DIV =`
First_YearDate=`gmt math -Q ${FirstYearDay} ${FirstYear} ADD =`
LastYear=`echo ${Last_Date} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$1)}'`
LastDay=`echo ${Last_Date} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$2)}'`
LastYearDay=`gmt math -Q ${LastDay} 365 DIV =`
Last_YearDate=`gmt math -Q ${LastYearDay} ${LastYear} ADD =`

StartYear=`echo ${StartDate} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$1)}'`
StartDay=`echo ${StartDate} | gmt info -fT -I1 -C | cut -f1 | awk -F- '{printf("%d\n",$2)}'`
StartYearDay=`gmt math -Q ${StartDay} 365 DIV =`
Start_YearDate=`gmt math -Q ${StartYearDay} ${StartYear} ADD =`
fi

# GMT廣域設定
gmt gmtset ${gmt_config}

# 繪製原始資料
gmt gmtset FORMAT_DATE_IN yyyy-mm-dd PS_MEDIA A4 PS_PAGE_ORIENTATION landscape

if [ -n ${StartDate} ];then
    LOSGap=`cat ${Input_Data} | awk '{printf("%.8f %.8f\n",$1,$2)}' | grep ${Start_YearDate} | awk '{print $2}'`
    echo ${LOSGap}
fi

gmt psbasemap -R${First_Date}/${Last_Date}/${Lower_D}/${Upper_D} -JX9i/4i -K -Bsx${YearAxis}Y -Bpxa${MonthAxis}Of${mAxis}o+l"Time" -Bpy${DAxis}+l"LOS (mm)" -BWSen+t"GPS Time Series Plot" -X1.5i -Y1.5i > ${Output_File_Name}
awk '{print $1, $2-'${LOSGap}'}' ${Input_Data} | gmt psxy -J -R${First_YearDate}/${Last_YearDate}/${Lower_D}/${Upper_D} -S${psxy_Size} -G${psxy_HG} -K -O -V >> ${Output_File_Name}

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
