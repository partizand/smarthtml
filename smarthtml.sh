#!/bin/sh

########################################################################
#
# S.M.A.R.T.Html v0.8.2 (c) 2016
#
# Author:   gSpot at wl500g.info
# License:  GPLv2
# Depends:      smartmontools
# Recommends:   rrdtool, sendmail, openssl
#
########################################################################

############################## Settings ################################
### Devices (example for multiple devices: DEVICES="/dev/sda /dev/sdb /dev/sdc")
DEVICES="/dev/sda"
### Disabled S.M.A.R.T. attributes (ex. vendor specific or unimportant attributes)
DISABLED_SMART_ATTRS="smart211 smart212 smart213 smart214 smart215 smart216 smart217 smart230"
### Temperature warning
TEMP_ALERT=60
### Show SCT temperature history (0 - disable; 1 - enable)
TEMP_HISTORY=1
### Write S.M.A.R.T. changes to device log (0 - only critical warnings; 1 - all changes)
LOG_ALL=0
### Write critical warnings to syslog (0 - disable; 1 - enable)
USE_LOGGER=1
### E-mail support for critical warnings (0 - disable; 1 - enable)
USE_MAIL=0
### Mail settings
MAIL_RECIPIENT="email@gmail.com"
MAIL_SENDER="email@gmail.com"
MAIL_LOGIN="email@gmail.com"
MAIL_PASSWORD="password"
MAIL_SMTP="smtp.gmail.com:25"
### RRD support (0 - disable; 1 - enable)
USE_RRD=1
### RRD database preset (1 - 30mins; 2 - 1hour; 3 - 3hours; 4 - 6hours; 5 - 12hours; 6 - 24hours)
RRD_DB_PRESET=3
### S.M.A.R.T. attributes for RRD
RRD_SMART_ATTRS="smart3 smart194" # Spin-up time & temperature
#RRD_SMART_ATTRS="smart194" # Only a temperature data for RRD
RRD_SMART_ATTR_DEF_PIC="smart194"
### CGI-module smarthtml.cgi (0 - disable; 1 - enable)
USE_CGI_MODULE=0

############################# Base config ##############################
export NAME="smarthtml"
export PATH="${PATH}:/bin:/sbin:/usr/bin:/usr/sbin:/opt/bin:/opt/sbin:/opt/usr/bin:/opt/usr/sbin"
export LANG="en_US.UTF-8"
AWKCMD="awk"
LOGGERCMD="logger"
SMARTCTL=`which smartctl`
if [ $? -ne 0 ]; then
    echo " Error! smartctl doesn't exists..." >&2
    exit 1
fi
SMARTCTL_PARAMS="-iAHf old -l scttemp"
RRDTOOLCMD=`which rrdtool`
if [ $USE_RRD -eq 1 -a $? -ne 0 ]; then
    echo " Error! rrdtool doesn't exists..." >&2
    USE_RRD=0
fi
OPENSSLCMD=`which openssl`
if [ $USE_MAIL -eq 1 -a $? -ne 0 ]; then
    echo " Error! openssl doesn't exists..." >&2
    USE_MAIL=0
fi
MTA=`which sendmail`
if [ $USE_MAIL -eq 1 -a $? -ne 0 ]; then
    echo " Error! MTA doesn't exists..." >&2
    USE_MAIL=0
fi
MTACMD="${MTA} ${MAIL_RECIPIENT} -au${MAIL_LOGIN} -ap${MAIL_PASSWORD} -f ${MAIL_SENDER} -H "
MTA_HELPER="exec ${OPENSSLCMD} s_client -quiet -tls1 -starttls smtp -connect ${MAIL_SMTP}"
SCRIPT_ROOT="/opt/var/smarthtml"
DB_DIR="${SCRIPT_ROOT}/db"
LOG_DIR="${SCRIPT_ROOT}/log"
MTA_MSG_FILE="${SCRIPT_ROOT}/email"
HTML_DIR="/opt/share/www"
HTML_OUTPUT="${HTML_DIR}/smart.html"
RRD_DB_DIR="${SCRIPT_ROOT}/rrd"
RRD_DB_EXT="rrd"
RRD_GRAPH_DIR="$HTML_DIR"
RRD_GRAPH_WWW_PATH="."
RRD_GRAPH_EXT="PNG"
RRD_GRAPH_WIDTH=600
RRD_GRAPH_HEIGHT=240
HTML_MAIN_BGCOLOR="#DDDDDD"
HTML_THEADER_FONTCOLOR="#4C4C4C"
HTML_BORDER_COLOR="#B5B5B5"
HTML_MAIN_FONT_COLOR="#333333"
RRD_GRAPH_COLOR_TEMP_WARN="#FF7474"
RRD_GRAPH_COLOR_AREA="#F9F9F9"
RRD_GRAPH_COLOR_LINE="#666666"
RRD_GRAPH_COLOR_BACK="$HTML_MAIN_BGCOLOR"
RRD_GRAPH_COLOR_SHADEA="$HTML_MAIN_BGCOLOR"
RRD_GRAPH_COLOR_SHADEB="$HTML_MAIN_BGCOLOR"
RRD_GRAPH_COLOR_CANVAS="$HTML_MAIN_BGCOLOR"
RRD_GRAPH_COLOR_FONT="$HTML_THEADER_FONTCOLOR"
RRD_GRAPH_COLOR_MGRID="#888888"
RRD_GRAPH_COLOR_GRID="$HTML_BORDER_COLOR"
RRD_GRAPH_COLOR_AXIS="$HTML_THEADER_FONTCOLOR"
RRD_GRAPH_COLOR_FRAME="$HTML_THEADER_FONTCOLOR"
RRD_GRAPH_COLOR_ARROW="$HTML_THEADER_FONTCOLOR"

case $RRD_DB_PRESET in
    1)  ### 30m
        RRD_DB_STEP=1800
        RRD_RRA_SET="RRA:MAX:0.5:1:336 RRA:MAX:0.5:2:744 RRA:MAX:0.5:48:365 RRA:MAX:0.5:240:365"
        RRD_GRAPH_START="-7days -30days -365days"
        #RRD_GRAPH_START="-14days -30days -365days -1825days"    # + 5 years graph
        RRD_GRAPH_END="now"
    ;;
    2)  ### 1h
        RRD_DB_STEP=3600
        RRD_RRA_SET="RRA:MAX:0.5:1:744 RRA:MAX:0.5:24:365 RRA:MAX:0.5:120:365"
        RRD_GRAPH_START="-7days -30days -365days"
        #RRD_GRAPH_START="-14days -30days -365days -1825days"    # + 5 years graph
        RRD_GRAPH_END="now"
    ;;
    3)  ### 3h
        RRD_DB_STEP=10800
        RRD_RRA_SET="RRA:MAX:0.5:1:248 RRA:MAX:0.5:8:365 RRA:MAX:0.5:40:365"
        RRD_GRAPH_START="-14days -30days -365days"
        #RRD_GRAPH_START="-14days -30days -365days -1825days"    # + 5 years graph
        RRD_GRAPH_END="now"
    ;;
    4)  ### 6h
        RRD_DB_STEP=21600
        RRD_RRA_SET="RRA:MAX:0.5:1:248 RRA:MAX:0.5:4:365 RRA:MAX:0.5:20:365"
        RRD_GRAPH_START="-14days -30days -365days"
        #RRD_GRAPH_START="-14days -30days -365days -1825days"    # + 5 years graph
        RRD_GRAPH_END="now"
    ;;
    5)  ### 12h
        RRD_DB_STEP=43200
        RRD_RRA_SET="RRA:MAX:0.5:1:248 RRA:MAX:0.5:2:365 RRA:MAX:0.5:10:365"
        RRD_GRAPH_START="-14days -30days -365days"
        #RRD_GRAPH_START="-14days -30days -365days -1825days"    # + 5 years graph
        RRD_GRAPH_END="now"
    ;;
    *)  ### 24h
        RRD_DB_STEP=86400
        RRD_RRA_SET="RRA:MAX:0.5:1:365 RRA:MAX:0.5:5:365"
        RRD_GRAPH_START="-14days -30days -365days"
        #RRD_GRAPH_START="-14days -30days -365days -1825days"    # + 5 years graph
        RRD_GRAPH_END="now"
    ;;
esac
RRD_INTERVAL=`expr $RRD_DB_STEP \* 2`

############################## Functions ###############################
Help () {
cat << EOF
Usage: `basename $0` [resetwarn|resetcount|makerrdgraph|mailtest|--help]
        norrd : Update SMART data only (doesn't call rrdtool update) (if USE_RRD is 1)
        resetwarn : Reset warnings
        resetcount : Reset change counters
        makerrdgraph : Call rrdtool graph (if USE_RRD is 1)
        mailtest : Send the test email (if USE_MAIL is 1)
        -h|--help : This message
Examples:
        `basename $0`
        `basename $0` norrd
        `basename $0` resetwarn
        `basename $0` resetcount
        `basename $0` makerrdgraph
        `basename $0` mailtest

EOF
    exit 0
}

MakeHtmlHeader () {
    local graphstart
cat << EOF > $HTML_OUTPUT
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"><head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>S.M.A.R.T.Html</title>
<style type="text/css">
body { margin: 0px; padding: 0px; background-color: ${HTML_MAIN_BGCOLOR}; font-family: sans-serif; font-size: 11pt; font-weight: 400; color: ${HTML_MAIN_FONT_COLOR} }
#main_layout { width: 100%; min-width: 760px }
a { text-decoration: none; outline: none; border-bottom: 1px dotted ${HTML_MAIN_FONT_COLOR}; color: ${HTML_MAIN_FONT_COLOR} }
a:hover { color: #000000 }
a:active { color: #000000 }
img { margin: 5px 0px 0px 0px }
table.header { width: 100%; background-color: #666666; font-size: 14pt; color: #F9F9F9; border-collapse: collapse }
table.header td { padding: 5px }
table.main { width: 100%; border-collapse: collapse }
tr.infoarea > td { padding: 5px; font-size: 10pt; color: ${HTML_THEADER_FONTCOLOR}; border-top: 0px; border-bottom: 1px solid ${HTML_BORDER_COLOR}; border-left: 0px; border-right: 0px }
tr.theader > td { padding: 5px 2px 5px 2px; font-size: 10pt; color: ${HTML_THEADER_FONTCOLOR}; border-top: 1px solid ${HTML_BORDER_COLOR}; border-bottom: 1px solid ${HTML_BORDER_COLOR}; border-left: 0px; border-right: 0px }
tr.list > td { padding: 5px 2px 5px 2px; border-top: 1px solid ${HTML_BORDER_COLOR}; border-bottom: 1px solid ${HTML_BORDER_COLOR}; border-left: 0px; border-right: 0px }
.thrshld { background-color: #FF7474; color: #FFFFFF }
.thrshld:hover { background-color: #FF8D8D }
.thrshld a { text-decoration: none; outline: none; border-bottom: 1px dotted #FFFFFF; color: #FFFFFF }
.degr { background-color: #FFD6D6 }
.degr:hover { background-color: #FFE1E1 }
.lowdegr { background-color: #FFF9DB }
.lowdegr:hover { background-color: #FFFCEA }
.impr { background-color: #E4FFE4 }
.impr:hover { background-color: #F1FFF1 }
.idle { background-color: #F7F7F7 }
.idle:hover { background-color: #FDFDFD }
.nonzero { background-color: #FFF6EE }
.nonzero:hover { background-color: #FFF9F5 }
td.last_value { font-weight: 700 }
span.legend { font-size: 8pt; font-weight: 400; padding: 4px; margin: 0px 4px 0px 4px; vertical-align: middle }
span.hex { font-size: 8pt; font-weight: 400; vertical-align: middle }
table.info_table { width: 700px; border-collapse: collapse }
div.temp_history { width: 700px; height: 200px; overflow: auto; text-align: left }
table.temp_history_table { margin: auto; width: 95%; border-collapse: collapse }
#screen_locker { position: absolute; top: 0px; left: 0px; width: 100%; height: 100%; background-color: ${HTML_MAIN_BGCOLOR}; text-align: center; font-weight: 700; opacity: 0.7; z-index: 1; display: none }
#screen_error { position: absolute; width: 100%; background-color: #F9F9F9; text-align: center; font-weight: 700 }
</style>
</head><body>
<script type="text/javascript">
    function showGraph(attr, title, img, file) {
        var linksstr="";
        for(var i = 0; i < start_suff_array.length; i++) {
            linksstr+=" | <a href=\"javascript:void(0)\" onclick=\"switchGraph('"+img+"', '${RRD_GRAPH_WWW_PATH}/"+file+"_"+start_suff_array[i]+".${RRD_GRAPH_EXT}')\">"+start_suff_array[i]+"</a>";
        };
        document.getElementById(title).innerHTML = "<br />"+attr+" "+linksstr;
        document.getElementById(img).src = "${RRD_GRAPH_WWW_PATH}/"+file+"_"+start_suff_array[0]+".${RRD_GRAPH_EXT}";
    };
    function switchGraph(img, src) {
        document.getElementById(img).src = src;
    };
    function sendCgiRequest(call, conf) {
        if(conf && !confirm(conf)) return;
        var XHR = ("onload" in new XMLHttpRequest()) ? XMLHttpRequest : XDomainRequest;
        var xhr = new XHR();
        xhr.open("GET", "/cgi-bin/smarthtml.cgi?call="+call, true);
        document.getElementById("screen_locker").style.display = "block";
        xhr.send();
        xhr.onreadystatechange = function() {
            if(xhr.readyState == 4) {
                if(xhr.status != 200) document.body.innerHTML = "<div id=\"screen_error\">Server error:<br />"+xhr.status+": "+xhr.statusText+"<br />"+xhr.responseText+"</div>";
                else window.location.reload(true);
            };
        };
    };
    var start_suff_array=[];
EOF
    for graphstart in $RRD_GRAPH_START
    do
        echo "    start_suff_array.push(\"${graphstart}\");" >> $HTML_OUTPUT
    done
    printf "    start_suff_array.sort(function(a, b){a = Number(a.replace(/[^0-9]*/), \"\"); b = Number(b.replace(/[^0-9]*/), \"\"); if(a < b) return -1; if(a > b) return 1; return 0});\n</script>" >> $HTML_OUTPUT
    echo "<div id=\"screen_locker\"><span class=\"idle\">&nbsp;Processing...&nbsp;</span></div><div id=\"main_layout\">" >> $HTML_OUTPUT
    if [ $USE_CGI_MODULE -eq 1 ]; then
cat << EOF >> $HTML_OUTPUT
<table class="main">
<tr class="infoarea"><td align="left">&nbsp;</td><td align="right">
<a href="javascript:void(0)" onclick="sendCgiRequest('refresh', false)">Check Now</a> | <a href="javascript:void(0)" onclick="sendCgiRequest('resetwarn', false)">Reset Warnings</a> | <a href="javascript:void(0)" onclick="sendCgiRequest('resetcount', 'All attribute counters will be reset... Are you sure?')">Reset Counters</a>
</td></tr>
</table>
EOF
    fi
}

MakeHtmlFooter () {
    echo "</div></body></html>" >> $HTML_OUTPUT
}

GetDateString () {
    date +%Y"."%m"."%d" "%H":"%M":"%S
}

MakeSMARTDB () {
    $SMARTCTL $SMARTCTL_PARAMS $1 | $AWKCMD '/^[0-9 ]{1,3} [a-zA-Z_-]+ / {sub(/^ */, "", $0); printf "0 0 0 %s %s\n", $10, $1}' > $2
}

ResetSMARTDB () {
    [ -e "$1" ] || exit 1
    $AWKCMD -v TYPE=$2 '{
                            if(TYPE == "warn") printf "0 %s %s", $2, $3;
                            else printf "%s 0 0", $1;
                            print " "$4,$5;
                        }' $1 > ${1}.tmp && mv -f ${1}.tmp $1
}

ResetSMARTDBAll () {
    local device_path
    for device_path in $DEVICES
    do
        local device=`echo "$device_path" | $AWKCMD -F "/" '{print $NF}'`
        local db_file="${DB_DIR}/${device}"
        [ -e "$db_file" ] || continue
        ResetSMARTDB $db_file $1
    done
}

MakeRRDDB () {
    if [ -e "$1" ]; then
        echo " MakeRRDDB Error! ${1} is already exists..." >&2
    else
        local attr
        eval `printf "%s create %s -s %s " $RRDTOOLCMD $1 $RRD_DB_STEP
        for attr in $RRD_SMART_ATTRS
        do
            printf "DS:%s:GAUGE:%s:0:U " $attr $RRD_INTERVAL
        done
        printf "${RRD_RRA_SET}\n"`
        if [ $? -ne 0 ]; then
            echo " MakeRRDDB Error! ${1} doesn't created..." >&2
        else
            echo " + RRD DB ${1} was created..."
        fi
    fi
}

FillRRDDB () {
    if [ -e "$1" ]; then
        eval `echo "$RRD_SMART_ATTRS" | $AWKCMD -v RRDTOOLCMD=$RRDTOOLCMD -v RRDDB_FILE=$1 '
                                            function makeRRDStringPart(_val) {
                                                for(i = 1; i <= NF; i++) {
                                                    attrvalue=(length(ENVIRON[$i]) == 0) ? 0 : ENVIRON[$i];
                                                    printf "%s%s", ((_val == 0) ? $i : attrvalue), ((i == NF) ? "" : ":");
                                                };
                                            }
                                            {
                                                printf "%s update %s -t ", RRDTOOLCMD, RRDDB_FILE;
                                                makeRRDStringPart(0);
                                                printf "%s", " N:";
                                                makeRRDStringPart(1);
                                                printf "%s", "\n";
                                                exit 0;
                                            }'`
    else
        echo " FillRRDDB Error! ${1} doesn't exists..." >&2
    fi
}

MakeRRDGraph () {
    if [ -e "$1" ]; then
        local attr graphstart
        for attr in $RRD_SMART_ATTRS
        do
            if [ "$attr" = "smart194" ]; then
                local units="C"
                local hrule="HRULE:${TEMP_ALERT}${RRD_GRAPH_COLOR_TEMP_WARN}:Warning(${TEMP_ALERT})"
            else
                local units="Units"
                local hrule=""
            fi
            for graphstart in $RRD_GRAPH_START
            do
                rrd_graph_file="${RRD_GRAPH_DIR}/${2}_${attr}_${graphstart}.${RRD_GRAPH_EXT}"
                $RRDTOOLCMD graph $rrd_graph_file --force-rules-legend --slope-mode --watermark "generated by ${NAME} at `GetDateString`" --width $RRD_GRAPH_WIDTH --height $RRD_GRAPH_HEIGHT --start "$graphstart" --end "$RRD_GRAPH_END" --title "${device_path} (${graphstart})" -v "$units" --imgformat "$RRD_GRAPH_EXT" --color BACK${RRD_GRAPH_COLOR_BACK} --color SHADEA${RRD_GRAPH_COLOR_SHADEA} --color SHADEB${RRD_GRAPH_COLOR_SHADEB} --color CANVAS${RRD_GRAPH_COLOR_CANVAS} --color FONT${RRD_GRAPH_COLOR_FONT} --color MGRID${RRD_GRAPH_COLOR_MGRID} --color GRID${RRD_GRAPH_COLOR_GRID}  --color AXIS${RRD_GRAPH_COLOR_AXIS} --color FRAME${RRD_GRAPH_COLOR_FRAME} --color ARROW${RRD_GRAPH_COLOR_ARROW} --font "TITLE:10:" --font "AXIS:8:" --font "UNIT:8:" --font "LEGEND:8:" \
                DEF:${attr}=${1}:${attr}:MAX \
                AREA:${attr}${RRD_GRAPH_COLOR_AREA}:${attr} \
                LINE1:${attr}${RRD_GRAPH_COLOR_LINE}: \
                GPRINT:${attr}:MAX:"Max = %1.0lf" \
                GPRINT:${attr}:MIN:"Min = %1.0lf" \
                GPRINT:${attr}:AVERAGE:"Avg = %1.1lf" \
                GPRINT:${attr}:LAST:"Last = %1.0lf  " ${hrule} > /dev/null
            done
        done
    else
        echo " MakeRRDGraph Error! ${1} doesn't exists..." >&2
    fi
}

GetSMART () {
    local device_path
    for device_path in $DEVICES
    do
        [ -b "$device_path" ] || continue
        local device=`echo "$device_path" | $AWKCMD -F "/" '{print $NF}'`
        local db_file="${DB_DIR}/${device}"
        local log_file="${LOG_DIR}/${device}.log"
        [ ! -e "$db_file" -o ! -s "$db_file" ] && MakeSMARTDB $device_path $db_file
        if [ -s "$db_file" ]; then
            export $($SMARTCTL $SMARTCTL_PARAMS $device_path | $AWKCMD -v TEMP_ALERT=$TEMP_ALERT -v HTML_OUTPUT=$HTML_OUTPUT -v LOG_FILE=$log_file -v DB_FILE=$db_file -v DB_FILE_TMP=${db_file}.tmp -v DATE="`GetDateString`" -v DEVICE_PATH=$device_path -v DEVICE=$device -v LOGGERCMD=$LOGGERCMD -v LOG_ALL=$LOG_ALL -v USE_LOGGER=$USE_LOGGER -v USE_MAIL=$USE_MAIL -v MTA_MSG_FILE=$MTA_MSG_FILE -v DISABLED_SMART_ATTRS="$DISABLED_SMART_ATTRS" -v TEMP_HISTORY=$TEMP_HISTORY -v USE_RRD=$USE_RRD -v RRD_SMART_ATTRS="$RRD_SMART_ATTRS" -v RRD_SMART_ATTR_DEF_PIC=$RRD_SMART_ATTR_DEF_PIC -v RRD_GRAPH_WWW_PATH=$RRD_GRAPH_WWW_PATH -v RRD_GRAPH_EXT=$RRD_GRAPH_EXT '
                                                    BEGIN {
                                                        unsupported_device=0; powercc=0; poweron=0; startstopcnt=0; selftest=""; def_smart_attr_title=""; devinfo_str=""; devicemodel="";
                                                        temphistory_str="<tr class=\"infoarea\"><td align=\"center\">Index</td><td align=\"center\" colspan=\"2\">Est. Time</td><td align=\"center\">Temp C</td><td align=\"left\">&nbsp;</td></tr>";
                                                        PROCINFO["sorted_in"]="@ind_str_asc";
                                                        split(RRD_SMART_ATTRS, rrdsmartarray, " ");
                                                        split(DISABLED_SMART_ATTRS, smartdisarray, " ");
                                                    }
                                                    function makeLogString(id, attrname, rval, val, wrst, trhd, sval, msg, critical) {
                                                        printf "%s -- %s -- %s %s -- %s -- Last=%s (VALUE=%s WORST=%s THRESH=%s) -- Saved=%s\n",  DATE, DEVICE_PATH, id, attrname, msg, rval, val, wrst, trhd, sval >>LOG_FILE;
                                                        if(critical == 1) {
                                                            if(USE_MAIL == 1)
                                                                printf "%s -- %s -- %s %s -- %s -- Last=%s (VALUE=%s WORST=%s THRESH=%s) -- Saved=%s\n",  DATE, DEVICE_PATH, id, attrname, msg, rval, val, wrst, trhd, sval >>MTA_MSG_FILE;
                                                            if(USE_LOGGER == 1)
                                                                system(LOGGERCMD " -t \"" ENVIRON["NAME"] "\" -p user.warning \"" DEVICE_PATH " -- " id " " attrname " -- " msg " -- Last=" rval " (VALUE=" val " WORST=" wrst " THRESH=" trhd ") -- Saved=" sval"\"");
                                                        };
                                                    };
                                                    function makeDeviceHeader(dev) {
                                                        printf "<table class=\"header\"><tr><td align=\"center\">%s&nbsp;|&nbsp;%s&nbsp;|&nbsp;Last&nbsp;check:&nbsp;%s</td></tr></table>\n", DEVICE_PATH, dev, DATE >>HTML_OUTPUT;
                                                    };
                                                    function checkSmart(id, val, type, critical, alert, isbad, logging,  _string, _impr_val, _degr_val, _stat_val, _change_val, _trclass, _str_log_value, _attrtitlestr) {
                                                        _string="";
                                                        while((getline _string <DB_FILE) > 0) {
                                                            _impr_val=0; _degr_val=0; _stat_val=0;
                                                            split(_string, _stringarray, " ");
                                                            if(_stringarray[5] == id) {
                                                                if(val > _stringarray[4]) {
                                                                    if(type == 1) {
                                                                        _impr_val=1; _stat_val=1;
                                                                    }
                                                                    else {
                                                                        _degr_val=1; _stat_val=(critical == 0) ? 2 : 3;
                                                                    };
                                                                }
                                                                else if(val < _stringarray[4]) {
                                                                    if(type == 1) {
                                                                        _degr_val=1; _stat_val=(critical == 0) ? 2 : 3;
                                                                    }
                                                                    else {
                                                                        _impr_val=1; _stat_val=1;
                                                                    };
                                                                }
                                                                else {
                                                                    _stat_val=(critical == 1 && val > 0) ? 4 : 0;
                                                                };
                                                                if((critical == 0 && alert > 0) && ((type != 1 && val >= alert) || (type == 1 && val <= alert)))
                                                                        _stat_val=3;
                                                                else if(critical == 1 && _stringarray[1] == 3)
                                                                    _stat_val=_stringarray[1];
                                                                ### HTML Output
                                                                _change_val=val-_stringarray[4];
                                                                stat_mark=(_change_val > 0) ? "+"_change_val"&uarr;" : (_change_val < 0) ? _change_val"&darr;" : "&nbsp;";
                                                                _trclass=(_stat_val == 4) ? "nonzero" : (_stat_val == 3) ? "degr" : (_stat_val == 2) ? "lowdegr" : (_stat_val == 1) ? "impr" : "idle";
                                                                if(isbad == 1) {
                                                                    _trclass="thrshld";
                                                                    _str_log_value=val" (THRESHOLD!)";
                                                                }
                                                                else _str_log_value=val;
                                                                _attrtitlestr="";
                                                                if(USE_RRD == 1) {
                                                                    for(i in rrdsmartarray) {
                                                                        if(RRD_SMART_ATTR_DEF_PIC == "smart"$1) def_smart_attr_title=$2;
                                                                        if(rrdsmartarray[i] == "smart"$1) {
                                                                            _attrtitlestr="<a href=\"javascript:void(0)\" onclick=\"showGraph(this.textContent, \047graph_attr_"DEVICE"\047, \047graph_img_"DEVICE"\047, \047"DEVICE"_smart"$1"\047)\">"$2"</a>";
                                                                            break;
                                                                        };
                                                                    };
                                                                };
                                                                if(length(_attrtitlestr) == 0) _attrtitlestr=$2;
                                                                printf "<tr class=\"list %s\"><td align=\"right\">%d <span class=\"hex\">(%.2X)</span></td><td align=\"left\">%s</td><td align=\"center\">%s</td><td align=\"center\">%s</td><td align=\"center\">%s</td><td align=\"center\">%s</td><td align=\"center\" class=\"last_value\">%d <span class=\"hex\">(%.12X)</span></td><td align=\"center\">%s</td><td align=\"center\">%s</td><td align=\"center\">%s</td></tr>\n", _trclass, $1, $1, _attrtitlestr, _stringarray[4], $4, $5, $6, val, val, _stringarray[2]+_degr_val, _stringarray[3]+_impr_val, stat_mark >>HTML_OUTPUT;
                                                                ### Log Output
                                                                if(_stat_val == 3 && ((type != 1 && val > _stringarray[4]) || (type == 1 && val < _stringarray[4])))
                                                                    makeLogString(id, $2, _str_log_value, $4, $5, $6, _stringarray[4], "WARNING!", 1);
                                                                else if(logging == 1 && (_stat_val == 1 || _stat_val == 2))
                                                                    makeLogString(id, $2, val, $4, $5, $6, _stringarray[4], "INFO", 0);
                                                                ### DB Output
                                                                printf "%s %s %s %s %s\n",  _stat_val, _stringarray[2]+_degr_val, _stringarray[3]+_impr_val, val, _stringarray[5] >>DB_FILE_TMP;
                                                            }
                                                        };
                                                        close(DB_FILE);
                                                    }
                                                    {
                                                        sub(/^ */, "", $0);
                                                        gsub("_", " ", $2);
                                                        isbad=0;
                                                        if($0 ~ /^Device does not support SMART/) {
                                                            unsupported_device=1;
                                                            makeDeviceHeader(devicemodel);
                                                            printf "<table class=\"main\"><tr class=\"infoarea\"><td align=\"center\"><b>Device does not support S.M.A.R.T.!</b><td></tr></table>" >>HTML_OUTPUT;
                                                            exit 1;
                                                        }
                                                        else if($0 ~ /^(Model Family|Device Model|Serial Number|Firmware Version|User Capacity|Sector Size|[S]?ATA Version is)/) {
                                                            split($0, devinfoarray, ":");
                                                            sub(/^ */, "", devinfoarray[2]);
                                                            devinfo_str=devinfo_str"<tr class=\"theader\"><td align=\"left\">"devinfoarray[1]" :</td><td align=\"left\">"devinfoarray[2]"</td></tr>";
                                                            if(devinfoarray[1] == "Device Model") devicemodel=devinfoarray[2];
                                                        }
                                                        else if($0 ~ /^=== START OF READ SMART DATA SECTION ===/) {
                                                            makeDeviceHeader(devicemodel);
                                                            printf "%s", "<table class=\"main\"><tr class=\"theader\"><td align=\"right\" width=\"8%\" rowspan=\"2\">Id#</td><td width=\"20%\" align=\"left\" rowspan=\"2\">Attribute name</td><td align=\"center\" width=\"8%\" rowspan=\"2\">Saved value<br />(RAW)</td><td align=\"center\" class=\"last_value\" colspan=\"4\">Last value:</td><td align=\"center\" width=\"8%\" rowspan=\"2\">Degr. count</td><td align=\"center\" width=\"8%\" rowspan=\"2\">Improv. count</td><td align=\"center\" width=\"8%\" rowspan=\"2\">Last change</td></tr><tr class=\"theader\"><td width=\"8%\" align=\"center\">VALUE</td><td width=\"8%\" align=\"center\">WORST</td><td width=\"8%\" align=\"center\">THRESH</td><td width=\"16%\" align=\"center\" class=\"last_value\">RAW <span class=\"hex\">(hex)</span></td></tr>\n" >>HTML_OUTPUT;
                                                        }
                                                        else if($0 ~ /^SMART overall-health self-assessment test result/)
                                                            selftest=(gensub(/^.*: /, "", 1, $0) ~ "PASSED") ? "<span class=\"impr\">&nbsp;"$0"&nbsp;</span>" : "<span class=\"thrshld\">&nbsp;"$0"&nbsp;</span>";
                                                        else if($0 ~ /^[0-9 ]{1,3} [a-zA-Z_-]+ /) {
                                                            for(i in smartdisarray) {
                                                                if("smart"$1 == smartdisarray[i]) next;
                                                            };
                                                            if($4 <= $6) isbad=1;
                                                            ### STDOUT
                                                            printf "smart%s=%s ", $1, $10;
                                                            if($1 == "4") startstopcnt=$10;
                                                            else if($1 == "9") poweron=$10;
                                                            else if($1 == "12") powercc=$10;
                                                            else if($1 ~ /^(5|11|184|187|196|197|198|200|202|220)$/) checkSmart($1, $10, 0, 1, 0, isbad, LOG_ALL);
                                                            else if($1 ~ /^(190|194)$/) checkSmart($1, $10, 0, 0, TEMP_ALERT, isbad, LOG_ALL);
                                                            else if($1 ~ /^(2|8)$/) checkSmart($1, $10, 1, 0, 0, isbad, LOG_ALL);
                                                            else checkSmart($1, $10, 0, 0, 0, isbad, LOG_ALL);
                                                        }
                                                        else if($0 ~ /^([0-9 ]{1,3}|[.]{3})[ ]{1,4}([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}|[.]{2}[(][0-9 ]+ skipped[)])/) {
                                                            temphistory_str_alert_class=($4 ~ /[0-9]{1,3}/ && $4 >= TEMP_ALERT) ? " degr" : "";
                                                            temphistory_str=temphistory_str"<tr class=\"infoarea"temphistory_str_alert_class"\"><td align=\"center\">"$1"</td><td align=\"right\">"$2"</td><td align=\"left\">"$3"</td><td align=\"center\">"$4"</td><td align=\"left\">"$5"</td></tr>";
                                                        };
                                                    }
                                                    END {
                                                        if(unsupported_device == 0) {
                                                            printf "<tr class=\"theader\"><td align=\"right\" colspan=\"10\">4 Start/Stop Count: <b>%s</b> | 9 Power-On Hours: <b>%s</b> | 12 Power Cycle Count: <b>%s</b></td></tr><tr class=\"theader\"><td align=\"center\" colspan=\"10\"><b>%s</b></td></tr></table><table class=\"main\">", startstopcnt, poweron, powercc, selftest >>HTML_OUTPUT;
                                                            if(USE_RRD == 1 && length(RRD_SMART_ATTR_DEF_PIC) > 0)
                                                                printf "<tr class=\"infoarea\"><td align=\"center\" valign=\"top\"><div id=\"graph_attr_"DEVICE"\"></div><img id=\"graph_img_"DEVICE"\" src=\"\" /><script type=\"text/javascript\">showGraph(\047"def_smart_attr_title"\047, \047graph_attr_"DEVICE"\047, \047graph_img_"DEVICE"\047, \047"DEVICE"_"RRD_SMART_ATTR_DEF_PIC"\047)</script></td></tr>" >>HTML_OUTPUT;
                                                            if(TEMP_HISTORY == 1)
                                                                printf "<tr class=\"infoarea\"><td align=\"center\" valign=\"top\"><br />SCT temperature history:<br /><br /><div class=\"temp_history\"><table class=\"temp_history_table\">%s</table></div><br /></td></tr>", temphistory_str >>HTML_OUTPUT;
                                                            printf "<tr class=\"infoarea\"><td align=\"center\" valign=\"top\"><br />Device info:<br /><br /><table class=\"info_table\">%s</table><br /></td></tr><tr class=\"infoarea\"><td align=\"right\"><span class=\"legend\">S.M.A.R.T. table legend:</span><span class=\"legend impr\">improved attr.</span><span class=\"legend lowdegr\">degr. non critical attr.</span><span class=\"legend nonzero\">critical attr. > 0</span><span class=\"legend degr\">degr. critical attr.</span><span class=\"legend thrshld\">threshold!</span></td></tr></table>\n", devinfo_str >>HTML_OUTPUT;
                                                        };
                                                        ### STDOUT
                                                        printf "unsupported_device=%s ", unsupported_device;
                                                    }' && mv -f ${db_file}.tmp $db_file)
            if [ $USE_RRD -eq 1 -a $unsupported_device -eq 0 -a $# -eq 1 -a "$1" = "rrd" ]; then
                local rrd_db_file="${RRD_DB_DIR}/${device}.${RRD_DB_EXT}"
                [ -e "$rrd_db_file" ] || MakeRRDDB $rrd_db_file
                FillRRDDB $rrd_db_file
                MakeRRDGraph $rrd_db_file $device
            fi
        fi
        unset unsupported_device ${RRD_SMART_ATTRS}
    done
}

SendMail () {
    [ -n "$1" -a "$1" != "-v" ] && exit 1
    if [ -e "$MTA_MSG_FILE" -a -s "$MTA_MSG_FILE" ]; then
        $AWKCMD 'BEGIN {printf "Subject: <%s Alert>\n\n", ENVIRON["NAME"]} {print $0}' $MTA_MSG_FILE | ${MTACMD}"${MTA_HELPER}" $1
    fi
    [ -e "$MTA_MSG_FILE" ] && rm -f $MTA_MSG_FILE
}

MainRun () {
    local dir
    for dir in "$SCRIPT_ROOT" "$DB_DIR" "$LOG_DIR" "$HTML_DIR" "$RRD_DB_DIR" "$RRD_GRAPH_DIR"
    do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" && echo " + New dir ${dir} ..."
        fi
    done
    [ -e "$MTA_MSG_FILE" ] && rm -f $MTA_MSG_FILE
    MakeHtmlHeader
    GetSMART $1
    MakeHtmlFooter
    [ $USE_MAIL -eq 1 ] && SendMail &> /dev/null
}

############################ Main section ##############################
case $1 in
    resetwarn)
        ResetSMARTDBAll warn
    ;;
    resetcount)
        ResetSMARTDBAll count
    ;;
    makerrdgraph)
        if [ $USE_RRD -eq 1 ]; then
            for device_path in $DEVICES
            do
                [ -b "$device_path" ] || continue
                device=`echo "$device_path" | $AWKCMD -F "/" '{print $NF}'`
                rrd_db_file="${RRD_DB_DIR}/${device}.${RRD_DB_EXT}"
                MakeRRDGraph $rrd_db_file $device
            done
        fi
    ;;
    mailtest)
        if [ $USE_MAIL -eq 1 ]; then
            echo "This is a test message..." > $MTA_MSG_FILE
            SendMail -v
        fi
    ;;
    norrd)
        MainRun
    ;;
    -h|--help|help)
        Help
    ;;
    *)
        MainRun rrd
    ;;
esac

exit 0;
