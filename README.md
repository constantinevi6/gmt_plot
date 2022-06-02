# gmt_plot

GMT plotting program for PSInSAR result.

Requrement:

- [GMT](https://github.com/GenericMappingTools/gmt): Generic Mapping Tools.

- [pyGMT](https://www.pygmt.org/latest/index.html): A Python interface for the Generic Mapping Tools.

- [laspy](https://laspy.readthedocs.io/en/latest/index.html): Python library for lidar LAS/LAZ IO.

- [conda](https://www.anaconda.com): Python package manager.

- [matplotlib](https://matplotlib.org): Visualization with Python

- [pyyaml](https://pyyaml.org): PyYAML is a full-featured YAML framework for the Python programming language.

- [chardet](https://pypi.org/project/chardet/):Universal encoding detector for Python 2 and 3

簡易安裝方式：
conda install -c conda-forge matplotlib pyyaml pygmt chardet

pip install laspy[lazrs,laszip]

===========================Shell script版===========================
使用舊版(Shell script版本)需要以下命令編譯lonlat2m：
g++ -std=c++11 -o lonlat2m lonlat2m.cpp -I/usr/include/boost169

boost版本請修改至安裝的版本。

Version history:
- Release Ver. 2.1.0
    - Feature: 新增GNSS三軸資料繪圖。
    - Fix: 修正無限制多執行緒造成電腦當機的問題。

- Release Ver. 2.1.0
    - Feature: 重新設計IO。
    - Feature: 重新定義多圖繪製。
    - Feature: 強化散佈圖繪製功能。
    - Feature: 新增通用型批次繪圖設定選項。
    - Fix: 修正多執行緒重複執行主執行緒的問題。
    
- Release Ver. 2.0.1
    - Feature: 支援輸入獨立檔案之時間序列繪圖。

- Release Ver. 2.0.0
    - Feature: 新增pygmt版本，支援速度場、時間序列繪圖。

- Release Ver. 1.0.0
    - Feature: Shell script版本，支援速度場、時間序列、GPS三維時序繪圖。