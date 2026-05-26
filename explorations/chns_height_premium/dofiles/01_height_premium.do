*------------------------------------------------------------------------------
* File:     explorations/chns_height_premium/dofiles/01_height_premium.do
* Project:  CHNS height premium exploration
* Author:   Codex
* Purpose:  使用 CHNS 最大可用截面估计身高溢价，并比较 OLS 与 IV 结果
* Inputs:   data/raw/CHNS_260521/chns_individual_wave_panel.csv
*           data/raw/CHNS_260521/wages_12.csv
*           explorations/chns_height_premium/scripts/build_height_core.py
* Outputs:  explorations/chns_height_premium/output/tables/
*           explorations/chns_height_premium/output/figures/
*           data/derived/chns_height_premium_merged_person_wave.dta
*           data/derived/chns_height_premium_analysis.dta
* Log:      explorations/chns_height_premium/logs/01_height_premium.log
*
* HOW TO RUN (from project root):
*     C:\ProgramData\Miniconda3\python.exe ^
*         explorations\chns_height_premium\scripts\build_height_core.py
*     bash scripts/run_stata.sh explorations/chns_height_premium/dofiles/01_height_premium.do
*
* 给初学者的说明：
*   这个 do-file 是一个完整的、可复现的小型实证项目。它先整理数据，
*   再自动选择可用人数最多的截面，最后估计 OLS 和 IV 回归。你可以把它
*   当作 Stata 入门模板来读：每一段都先说明“为什么做”，再说明“命令
*   做了什么”。所有数字结论都由本脚本生成的日志或表格支持。
*
* 当前回归结果来源：
*   explorations/chns_height_premium/output/tables/ols_iv_height_premium.csv
*   explorations/chns_height_premium/logs/01_height_premium.log
*
* 当前结果摘要，供阅读代码时对照：
*   - 最大完整 OLS 截面是 2011 年，OLS 样本量为 3,755。
*   - OLS 中，身高每增加 1 厘米，log 月劳动收入增加 0.00608，
*     聚类稳健标准误为 0.00166。
*   - IV 中，用父母平均身高作为工具变量，身高系数为 0.00522，
*     聚类稳健标准误为 0.01037，IV 样本量为 882。
*   - 第一阶段 F 统计量为 81.51，说明父母身高与本人身高相关性较强。
*   - 但是，父母身高可能还代表家庭背景、童年营养和地区环境，所以
*     exclusion restriction 不一定成立；IV 结果应解释为探索性结果。
*------------------------------------------------------------------------------

* `version 14` 告诉 Stata 用 Stata 14 的语法规则执行本文件。
* 这样即使以后电脑上装了更新版本的 Stata，旧脚本也更容易复现。
version 14

* `clear all` 清空内存中的数据、矩阵和估计结果。每个可独立运行的
* do-file 开头都应该清空环境，避免上一次运行留下的对象影响这一次。
clear all

* `set more off` 让 Stata 一次性跑完，不在输出很多行时停下来等你按键。
set more off

* `set varabbrev off` 禁止变量名缩写。初学者很容易把变量名打错；
* 关闭缩写以后，Stata 会直接报错，而不是猜测你想用哪个变量。
set varabbrev off

* 本脚本没有随机抽样或模拟，但项目规则要求统一设置 seed。
* 如果以后加入随机抽样，结果也会可复现。
set seed 20260526

* 如果前一次运行中断，可能有日志仍处于打开状态。`capture` 的意思是：
* 如果命令失败，不要让整个脚本停下来。这里用于安全地关闭旧日志。
capture log close

* `capture mkdir` 会创建文件夹；如果文件夹已经存在，也不会报错中断。
* 探索项目的日志、表格、图形都保存在自己的目录下，不污染主流水线。
capture mkdir "explorations/chns_height_premium/logs"
capture mkdir "explorations/chns_height_premium/output"
capture mkdir "explorations/chns_height_premium/output/tables"
capture mkdir "explorations/chns_height_premium/output/figures"

* 打开纯文本日志。日志是实证项目的审计记录：以后任何数字结论都应该
* 能在日志或输出表格中找到。
log using "explorations/chns_height_premium/logs/01_height_premium.log", ///
    replace text

* `local` 是 Stata 的局部宏。可以把它理解为“临时文本变量”：
* 以后写 `rawdir' 时，Stata 会替换成 data/raw/CHNS_260521。
* 这样路径只需要在这里维护一次。
local rawdir "data/raw/CHNS_260521"
local derived "data/derived/chns_height_premium_core.csv"
local derived_wage "data/derived/chns_height_premium_wages.csv"
local merged_dta "data/derived/chns_height_premium_merged_person_wave.dta"
local analysis_dta "data/derived/chns_height_premium_analysis.dta"
local outdir "explorations/chns_height_premium/output"

* `tempfile` 创建临时文件名。临时文件用于脚本中间步骤，Stata 运行结束
* 后会自动清理。这样不会在项目目录里留下很多中间垃圾文件。
tempfile main wage parent_h father_h mother_h wave_counts results summary

*--- 1. 读取核心变量窄表 ------------------------------------------------------
* Stata 14 不能从 CSV 直接只导入指定列；窄表由 Miniconda Python 辅助脚本生成。
* 为什么先生成窄表？
*   原始 CHNS 合并宽表有很多列。直接读完整宽表慢，也不利于初学者理解。
*   Python helper 只抽取本分析需要的变量，并写入 data/derived/。这些派生
*   个人级数据不会提交到 git，但你本地可以直接复现。
*
* `confirm file` 检查文件是否存在。`_rc` 是上一条命令的返回码：
*   _rc == 0 表示成功；
*   _rc != 0 表示失败。
capture confirm file "`derived'"
if _rc {
    display as error "Required narrow extract not found: `derived'"
    display as error "Run this first:"
    display as error "C:\ProgramData\Miniconda3\python.exe " ///
        "explorations\chns_height_premium\scripts\build_height_core.py"
    exit 601
}
capture confirm file "`derived_wage'"
if _rc {
    display as error "Required wage extract not found: `derived_wage'"
    display as error "Run the Miniconda helper listed above first."
    exit 601
}

* `import delimited` 读取 CSV。`varnames(1)` 表示第一行是变量名；
* `case(lower)` 尝试把变量名转成小写，减少大小写混乱。
import delimited using "`derived'", clear varnames(1) case(lower)

* 常见负值编码为 unknown/missing；具体变量再加合理范围限制。
* CHNS 问卷里常用 -9、-99、-999 等负值表示 unknown 或 not applicable。
* 回归不能把这些编码当成真实年龄、工资或身高，所以先改成 Stata 缺失值 `.`。
foreach v of varlist father_id mother_id gender age educ_a11 educ_a11a_93 ///
    educ_level working occupation employment_type hours_week height_cm weight_kg ///
    urban_index province urban {
    capture replace `v' = . if `v' < 0
}

* `generate` 创建新变量。这里把原始性别变量转成 male 虚拟变量：
*   male = 1 表示男性；
*   male = 0 表示女性；
*   其他值记为缺失。
generate byte male = (gender == 1) if inlist(gender, 1, 2)

* 教育变量说明：
*   A11 是 CHNS 的受教育年级编码，比如 23 表示初中三年级；
*   A11A_93 是部分年份直接报告的受教育年限。
* 最终回归不使用连续 educ_years，而使用 A12 的最高教育程度分类
* `educ_level`，因为 A11 不是简单的“年数”。
generate educ_years = educ_a11a_93
replace educ_years = educ_a11 if missing(educ_years) & inrange(educ_a11, 0, 30)
replace educ_years = . if !inrange(educ_years, 0, 30)
replace educ_level = . if !inrange(educ_level, 0, 6)

* 样本限制：
*   - 年龄限定为 18 到 65 岁，近似工作年龄人口；
*   - 身高限定为 120 到 220 厘米，去掉明显错误值；
*   - 体重限定为 30 到 200 公斤，主要用于描述统计；
*   - 城乡变量只保留 CHNS 合法编码 1 和 2。
replace age = . if !inrange(age, 18, 65)
replace height_cm = . if !inrange(height_cm, 120, 220)
replace weight_kg = . if !inrange(weight_kg, 30, 200)
replace hours_week = . if !inrange(hours_week, 1, 100)
replace urban = . if !inlist(urban, 1, 2)
replace male = . if missing(gender)

label variable height_cm "Height in centimeters"
label variable educ_level "Highest education level"
label variable male "Male"
label variable age "Age"
label variable urban "Urban site indicator, raw CHNS code"

* 把整理后的主表暂存到临时文件 `main'，后面再与工资表合并。
save `main', replace

*--- 2. 读取个人-年份工资窄表 --------------------------------------------------
* 工资原始文件是 job-level：一个人一年可能有主业和副业多条记录。
* Python helper 已经把它聚合到 person-year 层级：
*   monthly_wage         主业/副业月工资求和；
*   monthly_bonus        年奖金折算为月奖金；
*   monthly_labor_income 月工资 + 月奖金；
*   lmonthly_wage        log(monthly_labor_income)。
* 因变量用 log 工资是劳动经济学常见做法，系数可以近似解释为百分比变化。
import delimited using "`derived_wage'", clear varnames(1) case(lower)
save `wage', replace

*--- 3. 合并分析数据并构造父母身高 IV -----------------------------------------
* `use` 读入主表。`merge 1:1 idind wave using ...` 表示按照个人 ID 和
* 年份，把每个 person-year 与对应的工资记录合并。
*
* `keep(match master)` 的含义：
*   - 保留主表中的所有人年记录；
*   - 如果工资表中有匹配记录，就把工资变量并进来；
*   - 工资表中无法匹配到主表的记录不保留。
use `main', clear
merge 1:1 idind wave using `wage', keep(match master) nogen

* 构造父母身高工具变量的思路：
*   CHNS 家庭成员关系里有 father_id 和 mother_id。我们先计算每个人在
*   所有年份中可观测到的平均身高 parent_height，然后把父亲 ID 和母亲 ID
*   分别拿去匹配这个平均身高。
*
* `preserve` / `restore` 是成对命令：
*   preserve 先保存当前内存中的数据；
*   中间可以临时改数据、collapse 或保存临时表；
*   restore 再回到 preserve 之前的数据。
preserve
    keep idind height_cm
    keep if !missing(idind, height_cm)
    collapse (mean) parent_height = height_cm, by(idind)
    save `parent_h', replace
restore

preserve
    use `parent_h', clear
    rename idind father_id
    rename parent_height father_height
    save `father_h', replace
restore

preserve
    use `parent_h', clear
    rename idind mother_id
    rename parent_height mother_height
    save `mother_h', replace
restore

merge m:1 father_id using `father_h', keep(master match) nogen
merge m:1 mother_id using `mother_h', keep(master match) nogen

* `egen rowmean()` 逐行求平均。如果只有父亲或母亲身高可用，也会用
* 那一个可用值；如果两者都缺失，parent_height_avg 就缺失。
egen parent_height_avg = rowmean(father_height mother_height)
label variable parent_height_avg "Average parental height"

generate age2 = age^2
label variable age2 "Age squared"

*--- 4. 自动选择完整 OLS 样本最大的截面 --------------------------------------
* 这里不是手动指定年份，而是让数据告诉我们哪个截面可用人数最多。
* `ols_sample` 是一个 0/1 指示变量：只有当因变量、核心解释变量和控制
* 变量都不缺失时，才等于 1。
generate byte ols_sample = !missing(lmonthly_wage, height_cm, age, age2, ///
    male, educ_level, urban, province, commid)

* `compress` 会在不改变变量值的前提下压缩数据类型，减小 .dta 文件体积。
* 这个合并后的 person-wave 文件便于你以后直接打开检查变量构造。
compress
save "`merged_dta'", replace

preserve
    * 只在完整 OLS 样本里统计各年份人数。
    keep if ols_sample

    * `collapse (count) n_ols = idind, by(wave)` 把数据从“个人-年份”
    * 压缩成“年份”层级，每个 wave 一行，n_ols 是该年的可用样本数。
    collapse (count) n_ols = idind, by(wave)

    * `gsort -n_ols wave` 先按 n_ols 从大到小排序；如果人数相同，
    * 再按 wave 从小到大排序。
    gsort -n_ols wave

    * 保存每个 wave 的可用样本数，方便审计“为什么选 2011 年”。
    export delimited using "`outdir'/tables/wave_sample_counts.csv", ///
        replace
    list wave n_ols, noobs clean

    * 排序后第一行就是最大完整样本截面。
    scalar chosen_wave = wave[1]
restore

local chosen_wave = chosen_wave
display as text "Selected wave with largest OLS complete sample: " ///
    as result `chosen_wave'

keep if wave == `chosen_wave'
keep if ols_sample

* IV 样本比 OLS 样本小，因为 IV 还要求父母平均身高不缺失。
generate byte iv_sample = !missing(parent_height_avg)
label variable ols_sample "Complete OLS sample"
label variable iv_sample "Complete IV sample with parental height"
order idind wave hhid commid line lmonthly_wage monthly_labor_income ///
    height_cm parent_height_avg father_height mother_height age age2 ///
    male educ_level urban province iv_sample
compress

* 这个文件是你最方便复现回归的入口。打开它以后，可以直接运行第 6 节
* 的 OLS 与 IV 命令，不需要重新合并原始 CHNS 数据。
save "`analysis_dta'", replace
display as text "OLS sample observations in selected wave: " as result _N
count if iv_sample
display as text "IV sample observations in selected wave: " as result r(N)

*--- 5. 描述统计与图形 --------------------------------------------------------
* `preserve` 让我们临时生成描述统计表，不破坏当前内存中的分析样本。
* `postfile` 是 Stata 写自定义表格的一种方式：先打开一个临时结果表，
* 然后循环每个变量，把 N、均值、标准差、最小值、最大值写进去。
preserve
    keep lmonthly_wage monthly_labor_income height_cm parent_height_avg ///
        age educ_level male urban weight_kg hours_week
    tempfile sumdata
    postfile sh str32 variable double n mean sd min max using `summary', replace
    foreach v of varlist lmonthly_wage monthly_labor_income height_cm ///
        parent_height_avg age educ_level male urban weight_kg hours_week {
        quietly summarize `v'
        post sh ("`v'") (r(N)) (r(mean)) (r(sd)) (r(min)) (r(max))
    }
    postclose sh
    use `summary', clear
    export delimited using "`outdir'/tables/summary_stats.csv", replace
restore

* 直方图展示身高分布。`frequency` 表示纵轴是人数，不是密度。
* 图形同时导出 PDF 和 PNG：PDF 适合论文，PNG 适合预览或幻灯片。
histogram height_cm, frequency width(2) start(120) ///
    title("Height distribution") ///
    subtitle("CHNS selected wave `chosen_wave'") ///
    xtitle("Height (cm)") ytitle("Frequency") ///
    graphregion(color(white)) plotregion(color(white)) ///
    fcolor("49 145 255") lcolor(white)
graph export "`outdir'/figures/height_distribution.pdf", replace
graph export "`outdir'/figures/height_distribution.png", replace width(1600)

* 散点图展示身高和 log 工资的原始相关性，`lfit` 加一条线性拟合线。
* 注意：图上的拟合线只是双变量相关，不等于后面的多控制变量回归。
twoway ///
    (scatter lmonthly_wage height_cm, msymbol(oh) mcolor("49 145 255")) ///
    (lfit lmonthly_wage height_cm, lcolor(navy) lwidth(medthick)), ///
    title("Height and log monthly wage") ///
    subtitle("CHNS selected wave `chosen_wave'") ///
    xtitle("Height (cm)") ytitle("Log monthly wage plus bonus") ///
    legend(order(1 "Worker" 2 "Linear fit") position(6) cols(2)) ///
    graphregion(color(white)) plotregion(color(white))
graph export "`outdir'/figures/height_wage_scatter.pdf", replace
graph export "`outdir'/figures/height_wage_scatter.png", replace width(1600)

*--- 6. OLS 与 IV 回归 --------------------------------------------------------
* 控制变量：年龄二次项、性别、教育程度、城乡、省份。
* 标准误聚类到社区层级，减少同一社区劳动力市场与价格环境相关性带来的问题。
*
* OLS 模型可以写成：
*   log(月劳动收入)_i = a + b * 身高_i + 控制变量_i + e_i
*
* `c.height_cm` 中的 c. 表示 height_cm 是连续变量。
* `i.male`、`i.educ_level`、`i.urban`、`i.province` 中的 i. 表示分类变量，
* Stata 会自动生成一组虚拟变量，并省略一个基准组。
*
* 因变量是 log 工资时，身高系数 b 可以近似理解为：
*   身高增加 1 厘米，月劳动收入变化 100*b 个百分点。
*
* 当前 OLS 结果，来源：
*   explorations/chns_height_premium/output/tables/ols_iv_height_premium.csv
*   explorations/chns_height_premium/logs/01_height_premium.log
*   b = 0.00608，SE = 0.00166，N = 3,755，R2 = 0.303。
* 含义：在控制年龄、性别、教育程度、城乡和省份后，OLS 显示身高
* 每增加 1 厘米，log 月劳动收入约增加 0.00608，即大约 0.61%。
*
* 注意：这里把控制变量直接写在回归命令里，而不是使用 local macro。
* 原因是很多初学者会在 Do-file Editor 中只选中某几行运行。如果只运行
* 回归命令而没有先运行 `local controls ...`，Stata 会把 `controls'
* 当成空白，结果就变成“没有控制变量”的回归。直接展开控制变量可以
* 避免这种常见错误。

display as text ">>> OLS: log monthly wage on height <<<"
regress lmonthly_wage c.height_cm c.age c.age2 i.male i.educ_level ///
    i.urban i.province, vce(cluster commid)
estimates store m_ols
scalar ols_b = _b[height_cm]
scalar ols_se = _se[height_cm]
scalar ols_n = e(N)
scalar ols_r2 = e(r2)

* IV 的想法：
*   如果身高不仅反映外貌或体格，也反映家庭背景、童年营养和能力等因素，
*   OLS 的身高系数可能不是纯粹的“身高溢价”。工具变量法试图用一个
*   只影响本人身高、但不直接影响工资的变量来识别身高效应。
*
* 本脚本使用父母平均身高作为工具变量。相关性条件通常比较可信，因为
* 父母身高与子女身高有遗传相关性；第一阶段 F = 81.51 也支持相关性强。
* 但排除限制较弱：父母身高可能反映家庭资源、地区环境和童年健康条件，
* 这些因素可能直接影响工资。因此这个 IV 更适合作为课堂/探索例子。
*
* 第一阶段模型：
*   本人身高_i = p + q * 父母平均身高_i + 控制变量_i + u_i
display as text ">>> First stage: own height on parental height <<<"
regress height_cm c.parent_height_avg c.age c.age2 i.male ///
    i.educ_level i.urban i.province if iv_sample, vce(cluster commid)
test parent_height_avg
scalar fs_f = r(F)
estimates store m_first

* 二阶段最小二乘，Stata 语法：
*   ivregress 2sls 因变量 控制变量 (内生变量 = 工具变量), options
*
* 当前 IV 结果，来源：
*   explorations/chns_height_premium/output/tables/ols_iv_height_premium.csv
*   explorations/chns_height_premium/logs/01_height_premium.log
*   b = 0.00522，SE = 0.01037，N = 882，R2 = 0.283。
* 含义：IV 点估计约为 0.52% 的每厘米身高溢价，但标准误很大，
* p 值为 0.615，不能拒绝“身高系数为 0”的原假设。
display as text ">>> IV 2SLS: parent height instrument <<<"
ivregress 2sls lmonthly_wage c.age c.age2 i.male i.educ_level ///
    i.urban i.province (height_cm = parent_height_avg) if iv_sample, ///
    vce(cluster commid) first
estimates store m_iv
scalar iv_b = _b[height_cm]
scalar iv_se = _se[height_cm]
scalar iv_n = e(N)
scalar iv_r2 = e(r2)

* 把 OLS 与 IV 的核心结果写成一个简洁 CSV，方便在报告中引用。
* 这里保存的是身高系数、聚类标准误、样本量、R2 和第一阶段 F。
postfile rh str16 model double b_height se_height n r2 first_stage_f ///
    using `results', replace
post rh ("OLS") (ols_b) (ols_se) (ols_n) (ols_r2) (.)
post rh ("IV_2SLS") (iv_b) (iv_se) (iv_n) (iv_r2) (fs_f)
postclose rh

use `results', clear
label variable b_height "Coefficient on height_cm"
label variable se_height "Clustered standard error"
label variable first_stage_f "First-stage F for parent_height_avg"
export delimited using "`outdir'/tables/ols_iv_height_premium.csv", ///
    replace

display as text "Analysis finished. Inspect:"
display as text "  log:     explorations/chns_height_premium/logs/01_height_premium.log"
display as text "  tables:  explorations/chns_height_premium/output/tables/"
display as text "  figures: explorations/chns_height_premium/output/figures/"
display as text "  dta:     data/derived/chns_height_premium_analysis.dta"

log close
