clear all
* 设定工作目录
cd "~/Desktop/Stata绘图主题/"

* 安装相关的绘图主题包
foreach i in "blindschemes" "brewschemeextras" "feigenbaum" "prioscheme" "qlean" "scheme_rbn1mono" "scheme_scientific" "scheme_tufte" "scheme_virdis" "scheme-burd" "scheme-modern" "scheme-mrc" "scheme-pih" "scheme-tfl" "uncluttered" "vgsg3"{
	tssc install `i', replace
}

* 获取 Stata 中的主题列表
cap log close
log using "schemeslist.smcl", replace smcl
graph query, schemes
log close

infix strL v 1-200 using schemeslist.smcl, clear
keep if index(v, "{col 5}")
replace v = subinstr(v, "{res}", "", .)
gen scheme = ustrregexs(1) if ustrregexm(v, "5\}(.*)")
split scheme, parse("{col 20}")
keep scheme1
ren scheme1 scheme
save scheme, replace

* 编写一个 docx 文档快速展示这 84 个主题
sysuse auto, clear
* 线图 + 直方图
tw histogram mpg, width(5) ysc(alt axis(1)) || /// 
	line weight mpg, yaxis(2) ysc(alt axis(2)) sort ///
		name(a, replace) nodraw scheme(s2color)

* 线图 + 阴影图
sysuse auto, clear
sum price, mean
local mean = r(mean)
qui kdensity price, gen(x h) nodraw
tw line h x || ///
	area h x if x < `mean', name(b, replace) ///
	nodraw scheme(s2color)

* 散点图 + 拟合
tw sc price weight || ///
	lpolyci price weight, name(c, replace) ///
	nodraw scheme(s2color)

* 箱线图
generate order = _n
expand 3
bysort order : generate which = _n
drop if which == 1 & price > 5000
drop if which == 2 & price > 10000
label def which 1 "<= $5000" 2 "<= $10000" 3 "all"
label val which which
gr box mpg, over(which) over(foreign) ///
	name(d, replace) nodraw scheme(s2color)

gr combine a b c d, rows(2) scheme(s2color) xsize(20) ysize(12)

* 编写文档
clear all
putdocx begin, pagesize(A4) font("宋体", 14, black)
putdocx paragraph, halign(center) style(Title)
putdocx text ("Stata 中的绘图主题"), bold ///
	font("宋体", 18, black)
putdocx paragraph, halign(center) style(Subtitle)
putdocx text ("TidyFriday & Stata中文社区"), ///
	bold font("STKaiti", 12, black) linebreak
putdocx text ("2020 年 5 月 17 日"), bold ///
	font("STKaiti", 12, black) linebreak
putdocx save Stata中的绘图主题.docx, replace

* 安装相关的绘图主题
putdocx begin
putdocx paragraph, halign(center) style(Heading2)
putdocx text ("安装相关的绘图主题"), bold ///
	font("宋体", 14, black)
putdocx paragraph, halign(left) font("宋体", 14, black)
putdocx text ("1. 安装 tssc："), linebreak 
putdocx paragraph, halign(center)
putdocx image "assets/tssc.png", linebreak width(15cm)

putdocx paragraph, halign(left) font("宋体", 14, black)
putdocx text ("2. 安装绘图主题"), linebreak
putdocx paragraph, halign(center)
putdocx image "assets/scheme.png", linebreak width(15cm)

putdocx save Stata中的绘图主题.docx, append

* 使用每个绘图主题绘制一幅图并保存
clear all
use scheme, clear
cap mkdir assets
* vg_size 主题报错，可能这个主题有问题，就删除了它：
drop if scheme == "vg_size"
forval i = 80/`=_N'{
	local scheme = "`=scheme[`i']'"
	cap preserve
	sysuse auto, clear
	qui {
		* 线图 + 直方图
		tw histogram mpg, width(5) ysc(alt axis(1)) || /// 
			line weight mpg, yaxis(2) ysc(alt axis(2)) sort ///
			name(a, replace) nodraw scheme(`scheme')

		* 线图 + 阴影图
		sysuse auto, clear
		sum price, mean
		local mean = r(mean)
		qui kdensity price, gen(x h) nodraw
		tw line h x || ///
			area h x if x < `mean', name(b, replace) ///
			nodraw scheme(`scheme')

		* 散点图 + 拟合
		tw sc price weight || ///
			lpolyci price weight, name(c, replace) ///
			nodraw scheme(`scheme')

		* 箱线图
		generate order = _n
		expand 3
		bysort order : generate which = _n
		drop if which == 1 & price > 5000
		drop if which == 2 & price > 10000
		label def which 1 "<= $5000" 2 "<= $10000" 3 "all"
		label val which which
		gr box mpg, over(which) over(foreign) ///
			name(d, replace) nodraw scheme(`scheme')

		gr combine a b c d, rows(2) scheme(`scheme') xsize(20) ysize(12)
		gr export assets/`scheme'.png, replace
		di in green "`scheme' 绘制成功！"
	}
	restore
}

* 循环插入图片
putdocx begin
putdocx paragraph, halign(center) style(Heading2)
putdocx text ("绘图主题展示"), bold ///
	font("宋体", 14, black)
forval i = 1/`=_N'{
	putdocx paragraph, halign(center) style(Heading3)
	putdocx text ("主题：`=scheme[`i']'"), bold ///
		font("STKaiti", 12, black) linebreak
	putdocx image "assets/`=scheme[`i']'.png", linebreak width(15cm)
}
putdocx save Stata中的绘图主题.docx, append
